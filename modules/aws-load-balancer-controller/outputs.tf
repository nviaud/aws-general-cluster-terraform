output "irsa_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller (IRSA)"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "irsa_name" {
  description = "Name of IAM role for AWS Load Balancer Controller (IRSA)"
  value       = aws_iam_role.aws_load_balancer_controller.name
}
