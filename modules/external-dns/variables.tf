variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "domain_name" {
  description = "Domain name for external DNS"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "chart_version" {
  description = "External DNS Helm chart version"
  type        = string
  default     = "1.14.0"
}

variable "namespace" {
  description = "Kubernetes namespace for External DNS"
  type        = string
  default     = "external-dns"
}
