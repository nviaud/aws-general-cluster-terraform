# Gatekeeper Constraint Templates
# These define the policy logic that can be enforced

# Require specific labels on resources
resource "kubernetes_manifest" "k8srequiredlabels" {
  count = var.enable_required_labels ? 1 : 0

  manifest = yamldecode(file("${path.module}/manifests/k8srequiredlabels.yaml"))

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Block privileged containers
resource "kubernetes_manifest" "k8spspprivilegedcontainer" {
  count = var.enable_privileged_container_check ? 1 : 0

  manifest = yamldecode(file("${path.module}/manifests/k8spspprivilegedcontainer.yaml"))

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Restrict allowed container registries
resource "kubernetes_manifest" "k8sallowedrepos" {
  count = var.enable_allowed_repos ? 1 : 0

  manifest = yamldecode(file("${path.module}/manifests/k8sallowedrepos.yaml"))

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Require resource limits
resource "kubernetes_manifest" "k8scontainerlimits" {
  count = var.enable_container_limits ? 1 : 0

  manifest = yamldecode(file("${path.module}/manifests/k8scontainerlimits.yaml"))

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Block host namespaces (hostNetwork, hostPID, hostIPC)
resource "kubernetes_manifest" "k8spsphostnamespace" {
  count = var.enable_host_namespace_check ? 1 : 0

  manifest = yamldecode(file("${path.module}/manifests/k8spsphostnamespace.yaml"))

  depends_on = [time_sleep.wait_for_gatekeeper]
}
