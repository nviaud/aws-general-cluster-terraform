output "irsa_arn" {
  description = "ARN of IAM role for External DNS (IRSA)"
  value       = aws_iam_role.external_dns.arn
}

output "irsa_name" {
  description = "Name of IAM role for External DNS (IRSA)"
  value       = aws_iam_role.external_dns.name
}

output "namespace" {
  description = "Kubernetes namespace for External DNS"
  value       = kubernetes_namespace.external_dns.metadata[0].name
}
