variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for external DNS (must be a Route53 hosted zone)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for external DNS"
  type        = string
}

variable "mongodb_storage_size" {
  description = "Storage size for MongoDB persistent volume"
  type        = string
  default     = "20Gi"
}

variable "mongodb_replicas" {
  description = "Number of MongoDB replicas"
  type        = number
  default     = 3
}

variable "mongodb_version" {
  description = "MongoDB version to deploy"
  type        = string
  default     = "7.0.5"
}

variable "mongodb_backup_schedule" {
  description = "Cron schedule for MongoDB backups (default: daily at 2 AM UTC)"
  type        = string
  default     = "0 2 * * *"
}

variable "mongodb_backup_retention_days" {
  description = "Number of days to retain MongoDB backups in S3"
  type        = number
  default     = 30
}

variable "enable_karpenter" {
  description = "Enable Karpenter for node autoscaling"
  type        = bool
  default     = true
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_cert_manager" {
  description = "Enable Cert Manager"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = true
}

variable "enable_gateway_api" {
  description = "Enable Gateway API with Envoy"
  type        = bool
  default     = true
}

variable "enable_mongodb" {
  description = "Enable MongoDB deployment"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
