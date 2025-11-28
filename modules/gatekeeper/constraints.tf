# Gatekeeper Constraints
# These are instances of ConstraintTemplates that enforce actual policies

# Enforce required labels on namespaces and pods
resource "kubernetes_manifest" "required_labels" {
  count = var.enable_required_labels && length(var.required_labels) > 0 ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/manifests/constraint-required-labels.yaml", {
    excluded_namespaces = var.excluded_namespaces
    required_labels     = var.required_labels
  }))

  depends_on = [kubernetes_manifest.k8srequiredlabels]
}

# Block privileged containers
resource "kubernetes_manifest" "block_privileged_containers" {
  count = var.enable_privileged_container_check ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/manifests/constraint-block-privileged-containers.yaml", {
    excluded_namespaces = var.excluded_namespaces
  }))

  depends_on = [kubernetes_manifest.k8spspprivilegedcontainer]
}

# Restrict allowed container registries
resource "kubernetes_manifest" "allowed_repos" {
  count = var.enable_allowed_repos && length(var.allowed_repos) > 0 ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/manifests/constraint-allowed-repos.yaml", {
    excluded_namespaces = var.excluded_namespaces
    allowed_repos       = var.allowed_repos
  }))

  depends_on = [kubernetes_manifest.k8sallowedrepos]
}

# Require container resource limits
resource "kubernetes_manifest" "container_limits" {
  count = var.enable_container_limits ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/manifests/constraint-container-limits.yaml", {
    excluded_namespaces = var.excluded_namespaces
  }))

  depends_on = [kubernetes_manifest.k8scontainerlimits]
}

# Block host namespace usage
resource "kubernetes_manifest" "block_host_namespace" {
  count = var.enable_host_namespace_check ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/manifests/constraint-block-host-namespace.yaml", {
    excluded_namespaces = var.excluded_namespaces
  }))

  depends_on = [kubernetes_manifest.k8spsphostnamespace]
}
