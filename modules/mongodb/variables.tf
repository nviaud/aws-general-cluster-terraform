variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for MongoDB"
  type        = string
  default     = "mongodb"
}

variable "storage_size" {
  description = "Storage size for MongoDB persistent volume"
  type        = string
  default     = "20Gi"
}

variable "replicas" {
  description = "Number of MongoDB replicas"
  type        = number
  default     = 3
}

variable "mongodb_version" {
  description = "MongoDB version to deploy"
  type        = string
  default     = "7.0.5"
}

variable "operator_version" {
  description = "MongoDB Community Operator Helm chart version"
  type        = string
  default     = "0.9.0"
}

variable "backup_schedule" {
  description = "Cron schedule for MongoDB backups (default: daily at 2 AM)"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups in S3"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
