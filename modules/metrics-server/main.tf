# Metrics Server Module
# Provides container resource metrics for Horizontal Pod Autoscaler and kubectl top

# Metrics Server Helm Release
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_version
  namespace  = "kube-system"

  values = [
    yamlencode({
      # Replicas for high availability
      replicas = var.replicas

      # Resource limits
      resources = {
        limits = {
          cpu    = var.resources.limits.cpu
          memory = var.resources.limits.memory
        }
        requests = {
          cpu    = var.resources.requests.cpu
          memory = var.resources.requests.memory
        }
      }

      # Args for metrics-server
      args = [
        "--cert-dir=/tmp",
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
        "--kubelet-use-node-status-port",
        "--metric-resolution=15s"
      ]

      # API service configuration
      apiService = {
        create = true
      }

      # Service monitor for Prometheus (if installed)
      serviceMonitor = {
        enabled = false
      }

      # Security context
      podSecurityContext = {
        runAsNonRoot = true
        runAsUser    = 1000
        fsGroup      = 1000
      }

      securityContext = {
        allowPrivilegeEscalation = false
        capabilities = {
          drop = ["ALL"]
        }
        readOnlyRootFilesystem = true
        runAsNonRoot           = true
        runAsUser              = 1000
        seccompProfile = {
          type = "RuntimeDefault"
        }
      }

      # Tolerations to run on system nodes
      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]

      # Node affinity (prefer system nodes)
      affinity = {
        nodeAffinity = {
          preferredDuringSchedulingIgnoredDuringExecution = [
            {
              weight = 100
              preference = {
                matchExpressions = [
                  {
                    key      = "role"
                    operator = "In"
                    values   = ["system"]
                  }
                ]
              }
            }
          ]
        }
      }

      # Pod disruption budget
      podDisruptionBudget = {
        enabled      = var.replicas > 1
        minAvailable = var.replicas > 1 ? 1 : null
      }

      # Update strategy
      updateStrategy = {
        type = "RollingUpdate"
        rollingUpdate = {
          maxUnavailable = 1
        }
      }

      # Priority class for critical system components
      priorityClassName = "system-cluster-critical"
    })
  ]
}
