output "namespace" {
  description = "Kubernetes namespace for Gateway API"
  value       = kubernetes_namespace.envoy_gateway_system.metadata[0].name
}

output "gateway_class_name" {
  description = "Name of the default GatewayClass"
  value       = var.gateway_class_name
}

output "default_gateway_name" {
  description = "Name of the default Gateway"
  value       = "default-gateway"
}
