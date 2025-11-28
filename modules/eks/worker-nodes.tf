# Worker Nodes Configuration
# This file contains all resources related to EKS worker nodes including:
# - IAM roles and policies
# - Launch templates
# - Managed node groups

# IAM Role for Managed Node Groups
resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# IAM Policy Attachments for Node Role
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_container_registry_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ssm_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

# Launch Template for System Node Group
resource "aws_launch_template" "system" {
  name_prefix = "${var.cluster_name}-system-"
  description = "Launch template for system node group"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
      encrypted             = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name = "${var.cluster_name}-system-node"
      }
    )
  }

  tags = var.tags
}

# Managed Node Group for System Components (Karpenter, CoreDNS)
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.system_node_group.desired_size
    max_size     = var.system_node_group.max_size
    min_size     = var.system_node_group.min_size
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.system_node_group.instance_types
  capacity_type  = var.managed_node_group_defaults.capacity_type

  launch_template {
    id      = aws_launch_template.system.id
    version = "$Latest"
  }

  labels = {
    role                      = "system"
    "karpenter.sh/controller" = "true"
  }

  # Ensure CoreDNS and Karpenter run on these nodes
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_container_registry_policy,
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-system-node-group"
    }
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}
