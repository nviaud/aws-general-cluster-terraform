output "irsa_arn" {
  description = "ARN of IAM role for Cert Manager (IRSA)"
  value       = aws_iam_role.cert_manager.arn
}

output "irsa_name" {
  description = "Name of IAM role for Cert Manager (IRSA)"
  value       = aws_iam_role.cert_manager.name
}

output "namespace" {
  description = "Kubernetes namespace for Cert Manager"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}
