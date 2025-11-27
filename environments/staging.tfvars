# AWS Configuration
aws_region = "eu-west-1"

# Environment Configuration
environment  = "staging"
project_name = "cde"

# EKS Cluster Configuration
cluster_name    = "cde-staging-eks"
cluster_version = "1.28"

# VPC Configuration - Different CIDR to avoid conflicts
vpc_cidr        = "10.1.0.0/16"
azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

# DNS Configuration (for External DNS)
domain_name     = "staging.example.com"
route53_zone_id = "Z1234567890ABC"  # Replace with your actual Route53 zone ID

# MongoDB Configuration - Staging sizing (production-like but smaller)
mongodb_storage_size          = "30Gi"  # Medium storage for staging
mongodb_replicas              = 2       # 2 replicas for staging
mongodb_version               = "7.0.5"
mongodb_backup_schedule       = "0 2 * * *"  # Daily at 2 AM UTC
mongodb_backup_retention_days = 14           # Medium retention for staging

# Feature Flags - Enable all for staging testing
enable_karpenter                    = true
enable_aws_load_balancer_controller = true
enable_cert_manager                 = true
enable_external_dns                 = true
enable_gateway_api                  = true
enable_mongodb                      = true

# Tags
tags = {
  Environment = "staging"
  Project     = "cde"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
