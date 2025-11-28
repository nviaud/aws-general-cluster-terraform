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
  manifest = yamldecode(templatefile("${path.module}/manifests/gatewayclass.yaml", {
    gateway_class_name = var.gateway_class_name
    namespace          = var.namespace
  }))

  depends_on = [
    helm_release.envoy_gateway
  ]
}

# Create EnvoyProxy configuration
resource "kubernetes_manifest" "envoy_proxy_config" {
  manifest = yamldecode(templatefile("${path.module}/manifests/envoyproxy-config.yaml", {
    namespace = var.namespace
  }))

  depends_on = [
    helm_release.envoy_gateway
  ]
}

# Create a sample Gateway
resource "kubernetes_manifest" "default_gateway" {
  manifest = yamldecode(templatefile("${path.module}/manifests/default-gateway.yaml", {
    namespace          = var.namespace
    gateway_class_name = var.gateway_class_name
  }))

  depends_on = [
    kubernetes_manifest.gateway_class,
    kubernetes_manifest.envoy_proxy_config
  ]
}
