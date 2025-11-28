# Gatekeeper (OPA) Module
# Provides policy enforcement and governance for Kubernetes

# Namespace for Gatekeeper
resource "kubernetes_namespace" "gatekeeper_system" {
  metadata {
    name = "gatekeeper-system"

    labels = {
      "admission.gatekeeper.sh/ignore" = "no-self-managing"
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit" = "restricted"
      "pod-security.kubernetes.io/warn" = "restricted"
    }
  }
}

# Gatekeeper Helm Release
resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  version    = var.gatekeeper_version
  namespace  = kubernetes_namespace.gatekeeper_system.metadata[0].name

  values = [
    yamlencode({
      replicas = var.replicas

      # Audit configuration
      audit = {
        interval = var.audit_interval
        logLevel = var.log_level
      }

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

      # Mutation webhook (if enabled)
      enableMutation = var.enable_mutation

      # Validating webhook failure policy
      validatingWebhookFailurePolicy = var.webhook_failure_policy

      # Exempt namespaces from Gatekeeper
      excludedNamespaces = var.excluded_namespaces

      # Pod security context
      podSecurityContext = {
        runAsNonRoot = true
        runAsUser    = 1000
        fsGroup      = 999
      }

      # Security context
      securityContext = {
        allowPrivilegeEscalation = false
        capabilities = {
          drop = ["ALL"]
        }
        readOnlyRootFilesystem = true
        runAsNonRoot           = true
        runAsUser              = 1000
      }

      # Tolerations for system nodes
      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]

      # Node affinity (optional: prefer system nodes)
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
    })
  ]

  depends_on = [kubernetes_namespace.gatekeeper_system]
}

# Wait for Gatekeeper to be ready before applying constraints
resource "time_sleep" "wait_for_gatekeeper" {
  depends_on = [helm_release.gatekeeper]

  create_duration = "30s"
}
