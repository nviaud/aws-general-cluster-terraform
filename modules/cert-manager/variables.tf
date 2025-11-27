variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "chart_version" {
  description = "Cert Manager Helm chart version"
  type        = string
  default     = "v1.13.3"
}

variable "namespace" {
  description = "Kubernetes namespace for Cert Manager"
  type        = string
  default     = "cert-manager"
}
