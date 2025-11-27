# Kubernetes Namespace for Envoy Gateway
resource "kubernetes_namespace" "envoy_gateway_system" {
  metadata {
    name = var.namespace
  }
}

# Install Gateway API CRDs
resource "helm_release" "gateway_api_crds" {
  name       = "gateway-api-crds"
  namespace  = var.namespace
  repository = "https://gateway-api.sigs.k8s.io"
  chart      = "gateway-api"
  version    = "v1.0.0"

  set {
    name  = "crds.only"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.envoy_gateway_system
  ]
}

# Install Envoy Gateway
resource "helm_release" "envoy_gateway" {
  namespace        = var.namespace
  create_namespace = false
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy_gateway_version

  set {
    name  = "deployment.envoyGateway.resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "deployment.envoyGateway.resources.limits.memory"
    value = "1024Mi"
  }

  set {
    name  = "deployment.envoyGateway.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "deployment.envoyGateway.resources.requests.memory"
    value = "256Mi"
  }

  depends_on = [
    helm_release.gateway_api_crds,
    kubernetes_namespace.envoy_gateway_system
  ]
}

# Create a default GatewayClass
resource "kubernetes_manifest" "gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = var.gateway_class_name
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = "custom-proxy-config"
        namespace = var.namespace
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway
  ]
}

# Create EnvoyProxy configuration
resource "kubernetes_manifest" "envoy_proxy_config" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "custom-proxy-config"
      namespace = var.namespace
    }
    spec = {
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyService = {
            type = "LoadBalancer"
            annotations = {
              "service.beta.kubernetes.io/aws-load-balancer-type"                            = "nlb"
              "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
              "service.beta.kubernetes.io/aws-load-balancer-scheme"                          = "internet-facing"
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.envoy_gateway
  ]
}

# Create a sample Gateway
resource "kubernetes_manifest" "default_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "default-gateway"
      namespace = var.namespace
    }
    spec = {
      gatewayClassName = var.gateway_class_name
      listeners = [
        {
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        },
        {
          name     = "https"
          protocol = "HTTPS"
          port     = 443
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                kind = "Secret"
                name = "default-tls-cert"
              }
            ]
          }
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.gateway_class,
    kubernetes_manifest.envoy_proxy_config
  ]
}
