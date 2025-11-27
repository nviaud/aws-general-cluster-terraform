output "namespace" {
  description = "Kubernetes namespace for MongoDB"
  value       = kubernetes_namespace.mongodb.metadata[0].name
}

output "mongodb_admin_password" {
  description = "MongoDB admin password"
  value       = random_password.mongodb_password.result
  sensitive   = true
}

output "mongodb_connection_string" {
  description = "MongoDB connection string for replica set"
  value       = "mongodb://admin:${random_password.mongodb_password.result}@mongodb-replica-set-0.mongodb-replica-set-svc.${kubernetes_namespace.mongodb.metadata[0].name}.svc.cluster.local:27017,mongodb-replica-set-1.mongodb-replica-set-svc.${kubernetes_namespace.mongodb.metadata[0].name}.svc.cluster.local:27017,mongodb-replica-set-2.mongodb-replica-set-svc.${kubernetes_namespace.mongodb.metadata[0].name}.svc.cluster.local:27017/?replicaSet=mongodb-replica-set"
  sensitive   = true
}

output "mongodb_service_name" {
  description = "MongoDB service name"
  value       = "mongodb-replica-set-svc.${kubernetes_namespace.mongodb.metadata[0].name}.svc.cluster.local"
}

output "s3_backup_bucket" {
  description = "S3 bucket name for MongoDB backups"
  value       = aws_s3_bucket.mongodb_backups.bucket
}

output "s3_backup_bucket_arn" {
  description = "S3 bucket ARN for MongoDB backups"
  value       = aws_s3_bucket.mongodb_backups.arn
}

output "backup_service_account_name" {
  description = "Kubernetes service account name for backups"
  value       = kubernetes_service_account.mongodb_backup.metadata[0].name
}

output "backup_iam_role_arn" {
  description = "IAM role ARN for MongoDB backup"
  value       = aws_iam_role.mongodb_backup.arn
}

output "backup_schedule" {
  description = "Cron schedule for MongoDB backups"
  value       = var.backup_schedule
}
