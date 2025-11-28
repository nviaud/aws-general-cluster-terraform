# Gatekeeper Constraint Templates
# These define the policy logic that can be enforced

# Require specific labels on resources
resource "kubernetes_manifest" "k8srequiredlabels" {
  count = var.enable_required_labels ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8srequiredlabels"
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sRequiredLabels"
          }
          validation = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                labels = {
                  type        = "array"
                  description = "A list of labels and values the object must specify."
                  items = {
                    type = "object"
                    properties = {
                      key = { type = "string" }
                      allowedRegex = { type = "string" }
                    }
                  }
                }
              }
            }
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego   = <<-EOF
          package k8srequiredlabels

          violation[{"msg": msg, "details": {"missing_labels": missing}}] {
            provided := {label | input.review.object.metadata.labels[label]}
            required := {label | label := input.parameters.labels[_].key}
            missing := required - provided
            count(missing) > 0
            msg := sprintf("you must provide labels: %v", [missing])
          }

          violation[{"msg": msg}] {
            value := input.review.object.metadata.labels[key]
            expected := input.parameters.labels[_]
            expected.key == key
            expected.allowedRegex != ""
            not re_match(expected.allowedRegex, value)
            msg := sprintf("Label <%v: %v> does not satisfy allowed regex: %v", [key, value, expected.allowedRegex])
          }
        EOF
      }]
    }
  }

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Block privileged containers
resource "kubernetes_manifest" "k8spspprivilegedcontainer" {
  count = var.enable_privileged_container_check ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8spspprivilegedcontainer"
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sPSPPrivilegedContainer"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego   = <<-EOF
          package k8spspprivileged

          violation[{"msg": msg, "details": {}}] {
            c := input_containers[_]
            c.securityContext.privileged
            msg := sprintf("Privileged container is not allowed: %v", [c.name])
          }

          input_containers[c] {
            c := input.review.object.spec.containers[_]
          }

          input_containers[c] {
            c := input.review.object.spec.initContainers[_]
          }
        EOF
      }]
    }
  }

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Restrict allowed container registries
resource "kubernetes_manifest" "k8sallowedrepos" {
  count = var.enable_allowed_repos ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8sallowedrepos"
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sAllowedRepos"
          }
          validation = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                repos = {
                  type        = "array"
                  description = "The list of prefixes a container image is allowed to have."
                  items = {
                    type = "string"
                  }
                }
              }
            }
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego   = <<-EOF
          package k8sallowedrepos

          violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
            not any(satisfied)
            msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
          }

          violation[{"msg": msg}] {
            container := input.review.object.spec.initContainers[_]
            satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
            not any(satisfied)
            msg := sprintf("initContainer <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
          }
        EOF
      }]
    }
  }

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Require resource limits
resource "kubernetes_manifest" "k8scontainerlimits" {
  count = var.enable_container_limits ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8scontainerlimits"
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sContainerLimits"
          }
          validation = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                cpu = { type = "string" }
                memory = { type = "string" }
              }
            }
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego   = <<-EOF
          package k8scontainerlimits

          missing(obj, field) {
            not obj[field]
          }

          missing(obj, field) {
            obj[field] == ""
          }

          violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            missing(container.resources.limits, "cpu")
            msg := sprintf("container <%v> has no cpu limit", [container.name])
          }

          violation[{"msg": msg}] {
            container := input.review.object.spec.containers[_]
            missing(container.resources.limits, "memory")
            msg := sprintf("container <%v> has no memory limit", [container.name])
          }
        EOF
      }]
    }
  }

  depends_on = [time_sleep.wait_for_gatekeeper]
}

# Block host namespaces (hostNetwork, hostPID, hostIPC)
resource "kubernetes_manifest" "k8spsphostnamespace" {
  count = var.enable_host_namespace_check ? 1 : 0

  manifest = {
    apiVersion = "templates.gatekeeper.sh/v1"
    kind       = "ConstraintTemplate"
    metadata = {
      name = "k8spsphostnamespace"
    }
    spec = {
      crd = {
        spec = {
          names = {
            kind = "K8sPSPHostNamespace"
          }
        }
      }
      targets = [{
        target = "admission.k8s.gatekeeper.sh"
        rego   = <<-EOF
          package k8spsphostnamespace

          violation[{"msg": msg, "details": {}}] {
            input.review.object.spec.hostNetwork
            msg := "Pod is using hostNetwork"
          }

          violation[{"msg": msg, "details": {}}] {
            input.review.object.spec.hostPID
            msg := "Pod is using hostPID"
          }

          violation[{"msg": msg, "details": {}}] {
            input.review.object.spec.hostIPC
            msg := "Pod is using hostIPC"
          }
        EOF
      }]
    }
  }

  depends_on = [time_sleep.wait_for_gatekeeper]
}
