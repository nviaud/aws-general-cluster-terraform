variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "gatekeeper_version" {
  description = "Gatekeeper Helm chart version"
  type        = string
  default     = "3.15.0"
}

variable "replicas" {
  description = "Number of Gatekeeper controller replicas"
  type        = number
  default     = 3
}

variable "audit_interval" {
  description = "Audit interval in seconds"
  type        = number
  default     = 60
}

variable "log_level" {
  description = "Log level for Gatekeeper (INFO, DEBUG, ERROR)"
  type        = string
  default     = "INFO"
}

variable "enable_mutation" {
  description = "Enable mutation webhook"
  type        = bool
  default     = false
}

variable "webhook_failure_policy" {
  description = "Validating webhook failure policy (Ignore or Fail)"
  type        = string
  default     = "Ignore"

  validation {
    condition     = contains(["Ignore", "Fail"], var.webhook_failure_policy)
    error_message = "webhook_failure_policy must be either 'Ignore' or 'Fail'"
  }
}

variable "excluded_namespaces" {
  description = "Namespaces to exclude from Gatekeeper policies"
  type        = list(string)
  default = [
    "kube-system",
    "kube-public",
    "kube-node-lease",
    "gatekeeper-system",
    "karpenter",
  ]
}

variable "resources" {
  description = "Resource limits and requests for Gatekeeper pods"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "1000m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
  }
}

# Policy Configuration
variable "enable_required_labels" {
  description = "Enable required labels policy"
  type        = bool
  default     = true
}

variable "required_labels" {
  description = "Required labels for resources"
  type = list(object({
    key          = string
    allowedRegex = string
  }))
  default = [
    {
      key          = "app"
      allowedRegex = ""
    },
    {
      key          = "environment"
      allowedRegex = "^(dev|staging|prod)$"
    }
  ]
}

variable "enable_privileged_container_check" {
  description = "Enable check to block privileged containers"
  type        = bool
  default     = true
}

variable "enable_allowed_repos" {
  description = "Enable allowed container registries policy"
  type        = bool
  default     = true
}

variable "allowed_repos" {
  description = "List of allowed container registry prefixes"
  type        = list(string)
  default = [
    "public.ecr.aws/",
    "602401143452.dkr.ecr",  # Amazon ECR
    "docker.io/library/",     # Docker Hub official
    "ghcr.io/",               # GitHub Container Registry
    "quay.io/",               # Quay.io
  ]
}

variable "enable_container_limits" {
  description = "Enable policy requiring container resource limits"
  type        = bool
  default     = true
}

variable "enable_host_namespace_check" {
  description = "Enable check to block hostNetwork/hostPID/hostIPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
