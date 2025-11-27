output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = module.eks.cluster_version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.oidc_provider_arn
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "karpenter_node_role_arn" {
  description = "ARN of IAM role for Karpenter nodes"
  value       = var.enable_karpenter ? module.karpenter[0].node_role_arn : null
}

output "karpenter_irsa_arn" {
  description = "ARN of IAM role for Karpenter controller (IRSA)"
  value       = var.enable_karpenter ? module.karpenter[0].irsa_arn : null
}

output "mongodb_admin_password" {
  description = "MongoDB admin password"
  value       = var.enable_mongodb ? module.mongodb[0].mongodb_admin_password : null
  sensitive   = true
}

output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value       = var.enable_mongodb ? module.mongodb[0].mongodb_connection_string : null
  sensitive   = true
}

output "mongodb_s3_backup_bucket" {
  description = "S3 bucket for MongoDB backups"
  value       = var.enable_mongodb ? module.mongodb[0].s3_backup_bucket : null
}

output "mongodb_backup_schedule" {
  description = "MongoDB backup cron schedule"
  value       = var.enable_mongodb ? module.mongodb[0].backup_schedule : null
}
