# AWS Configuration - LocalStack
aws_region = "us-east-1"  # LocalStack default region

# Environment Configuration
environment  = "local"
project_name = "cde"

# EKS Cluster Configuration
# Note: EKS is not fully supported in LocalStack Community Edition
# This is primarily for testing infrastructure code structure
cluster_name    = "cde-local-eks"
cluster_version = "1.28"

# VPC Configuration - Local network ranges
vpc_cidr        = "10.99.0.0/16"
azs             = ["us-east-1a", "us-east-1b"]  # LocalStack has limited AZ support
private_subnets = ["10.99.1.0/24", "10.99.2.0/24"]
public_subnets  = ["10.99.101.0/24", "10.99.102.0/24"]

# DNS Configuration (for External DNS)
# LocalStack Route53 endpoints
domain_name     = "local.example.com"
route53_zone_id = "Z1234567890ABC"  # Will be created in LocalStack

# MongoDB Configuration - Minimal local sizing
mongodb_storage_size          = "5Gi"   # Minimal for local
mongodb_replicas              = 1       # Single replica for local
mongodb_version               = "7.0.5"
mongodb_backup_schedule       = "0 2 * * *"
mongodb_backup_retention_days = 1       # Minimal retention for local

# Feature Flags - Disable features not supported by LocalStack
# Note: EKS and Kubernetes resources have limited LocalStack support
enable_karpenter                    = false  # Requires EKS
enable_aws_load_balancer_controller = false  # Requires EKS
enable_cert_manager                 = false  # Requires Kubernetes
enable_external_dns                 = false  # Requires Route53 (can enable with LocalStack Pro)
enable_gateway_api                  = false  # Requires Kubernetes
enable_mongodb                      = false  # Requires EKS
enable_gatekeeper                   = false  # Requires Kubernetes
enable_metrics_server               = false  # Requires Kubernetes

# Tags
tags = {
  Environment = "local"
  Project     = "cde"
  ManagedBy   = "Terraform"
  LocalStack  = "true"
}
