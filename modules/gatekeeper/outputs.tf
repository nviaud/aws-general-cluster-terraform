output "namespace" {
  description = "Gatekeeper namespace"
  value       = kubernetes_namespace.gatekeeper_system.metadata[0].name
}

output "helm_release_name" {
  description = "Gatekeeper Helm release name"
  value       = helm_release.gatekeeper.name
}

output "helm_release_version" {
  description = "Gatekeeper Helm chart version"
  value       = helm_release.gatekeeper.version
}

output "policies_enabled" {
  description = "List of enabled policies"
  value = {
    required_labels           = var.enable_required_labels
    privileged_container_check = var.enable_privileged_container_check
    allowed_repos             = var.enable_allowed_repos
    container_limits          = var.enable_container_limits
    host_namespace_check      = var.enable_host_namespace_check
  }
}
