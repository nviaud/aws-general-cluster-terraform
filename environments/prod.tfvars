# AWS Configuration
aws_region = "eu-west-1"

# Environment Configuration
environment  = "prod"
project_name = "cde"

# EKS Cluster Configuration
cluster_name    = "cde-prod-eks"
cluster_version = "1.28"

# VPC Configuration - Different CIDR to avoid conflicts
vpc_cidr        = "10.2.0.0/16"
azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

# DNS Configuration (for External DNS)
domain_name     = "example.com"  # Production domain
route53_zone_id = "Z1234567890ABC"  # Replace with your actual Route53 zone ID

# MongoDB Configuration - Production sizing
mongodb_storage_size          = "100Gi"  # Large storage for production
mongodb_replicas              = 3        # 3 replicas for HA
mongodb_version               = "7.0.5"
mongodb_backup_schedule       = "0 2 * * *"  # Daily at 2 AM UTC
mongodb_backup_retention_days = 90           # Longer retention for production

# Feature Flags - Production configuration
enable_karpenter                    = true
enable_aws_load_balancer_controller = true
enable_cert_manager                 = true
enable_external_dns                 = true
enable_gateway_api                  = true
enable_mongodb                      = true

# Tags
tags = {
  Environment = "prod"
  Project     = "cde"
  ManagedBy   = "Terraform"
  CostCenter  = "Production"
  Compliance  = "Required"
}
