output "node_role_arn" {
  description = "ARN of IAM role for Karpenter nodes"
  value       = aws_iam_role.karpenter_node.arn
}

output "node_role_name" {
  description = "Name of IAM role for Karpenter nodes"
  value       = aws_iam_role.karpenter_node.name
}

output "irsa_arn" {
  description = "ARN of IAM role for Karpenter controller (IRSA)"
  value       = aws_iam_role.karpenter_controller.arn
}

output "irsa_name" {
  description = "Name of IAM role for Karpenter controller (IRSA)"
  value       = aws_iam_role.karpenter_controller.name
}

output "queue_name" {
  description = "Name of SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter.name
}

output "queue_url" {
  description = "URL of SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter.url
}

output "instance_profile_name" {
  description = "Name of instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter_node.name
}
