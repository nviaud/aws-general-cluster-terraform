variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "metrics_server_version" {
  description = "Metrics Server Helm chart version"
  type        = string
  default     = "3.12.1"
}

variable "replicas" {
  description = "Number of metrics-server replicas for high availability"
  type        = number
  default     = 2
}

variable "resources" {
  description = "Resource limits and requests for metrics-server pods"
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
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
