variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS cluster and nodes"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "managed_node_group_defaults" {
  description = "Default settings for managed node groups"
  type = object({
    instance_types = list(string)
    capacity_type  = string
  })
  default = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
  }
}

variable "system_node_group" {
  description = "Configuration for system node group (for Karpenter and CoreDNS)"
  type = object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
  })
  default = {
    desired_size   = 2
    min_size       = 2
    max_size       = 4
    instance_types = ["t3.medium"]
  }
}
