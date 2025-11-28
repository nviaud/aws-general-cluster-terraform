# CoreDNS Add-on
# Provides DNS service for the Kubernetes cluster
# Configured to run on system nodes with CriticalAddonsOnly taint

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.6"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    tolerations = [
      {
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }
    ]
    nodeSelector = {
      role = "system"
    }
  })

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}
