# Gatekeeper Constraints
# These are instances of ConstraintTemplates that enforce actual policies

# Enforce required labels on namespaces and pods
resource "kubernetes_manifest" "required_labels" {
  count = var.enable_required_labels && length(var.required_labels) > 0 ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sRequiredLabels"
    metadata = {
      name = "required-labels"
    }
    spec = {
      match = {
        kinds = [
          { apiGroups = [""], kinds = ["Namespace"] },
          { apiGroups = [""], kinds = ["Pod"] },
          { apiGroups = ["apps"], kinds = ["Deployment", "StatefulSet", "DaemonSet"] },
        ]
        excludedNamespaces = var.excluded_namespaces
      }
      parameters = {
        labels = var.required_labels
      }
    }
  }

  depends_on = [kubernetes_manifest.k8srequiredlabels]
}

# Block privileged containers
resource "kubernetes_manifest" "block_privileged_containers" {
  count = var.enable_privileged_container_check ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sPSPPrivilegedContainer"
    metadata = {
      name = "block-privileged-containers"
    }
    spec = {
      match = {
        kinds = [
          { apiGroups = [""], kinds = ["Pod"] },
        ]
        excludedNamespaces = var.excluded_namespaces
      }
    }
  }

  depends_on = [kubernetes_manifest.k8spspprivilegedcontainer]
}

# Restrict allowed container registries
resource "kubernetes_manifest" "allowed_repos" {
  count = var.enable_allowed_repos && length(var.allowed_repos) > 0 ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sAllowedRepos"
    metadata = {
      name = "allowed-repos"
    }
    spec = {
      match = {
        kinds = [
          { apiGroups = [""], kinds = ["Pod"] },
        ]
        excludedNamespaces = var.excluded_namespaces
      }
      parameters = {
        repos = var.allowed_repos
      }
    }
  }

  depends_on = [kubernetes_manifest.k8sallowedrepos]
}

# Require container resource limits
resource "kubernetes_manifest" "container_limits" {
  count = var.enable_container_limits ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sContainerLimits"
    metadata = {
      name = "container-must-have-limits"
    }
    spec = {
      match = {
        kinds = [
          { apiGroups = [""], kinds = ["Pod"] },
        ]
        excludedNamespaces = var.excluded_namespaces
      }
    }
  }

  depends_on = [kubernetes_manifest.k8scontainerlimits]
}

# Block host namespace usage
resource "kubernetes_manifest" "block_host_namespace" {
  count = var.enable_host_namespace_check ? 1 : 0

  manifest = {
    apiVersion = "constraints.gatekeeper.sh/v1beta1"
    kind       = "K8sPSPHostNamespace"
    metadata = {
      name = "block-host-namespace"
    }
    spec = {
      match = {
        kinds = [
          { apiGroups = [""], kinds = ["Pod"] },
        ]
        excludedNamespaces = var.excluded_namespaces
      }
    }
  }

  depends_on = [kubernetes_manifest.k8spsphostnamespace]
}
