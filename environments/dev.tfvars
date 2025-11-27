# AWS Configuration
aws_region = "eu-west-1"

# Environment Configuration
environment  = "dev"
project_name = "cde"

# EKS Cluster Configuration
cluster_name    = "cde-dev-eks"
cluster_version = "1.28"

# VPC Configuration
vpc_cidr        = "10.0.0.0/16"
azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# DNS Configuration (for External DNS)
domain_name     = "dev.example.com"
route53_zone_id = "Z1234567890ABC"  # Replace with your actual Route53 zone ID

# MongoDB Configuration - Development sizing
mongodb_storage_size          = "10Gi"  # Smaller storage for dev
mongodb_replicas              = 1       # Single replica for dev
mongodb_version               = "7.0.5"
mongodb_backup_schedule       = "0 2 * * *"  # Daily at 2 AM UTC
mongodb_backup_retention_days = 7            # Shorter retention for dev

# Feature Flags - Enable all for development testing
enable_karpenter                    = true
enable_aws_load_balancer_controller = true
enable_cert_manager                 = true
enable_external_dns                 = true
enable_gateway_api                  = true
enable_mongodb                      = true

# Tags
tags = {
  Environment = "dev"
  Project     = "cde"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}
