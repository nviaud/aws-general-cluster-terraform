output "helm_release_name" {
  description = "Metrics Server Helm release name"
  value       = helm_release.metrics_server.name
}

output "helm_release_version" {
  description = "Metrics Server Helm chart version"
  value       = helm_release.metrics_server.version
}

output "namespace" {
  description = "Namespace where Metrics Server is deployed"
  value       = helm_release.metrics_server.namespace
}
