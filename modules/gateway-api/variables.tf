variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "envoy_gateway_version" {
  description = "Envoy Gateway Helm chart version"
  type        = string
  default     = "v0.6.0"
}

variable "namespace" {
  description = "Kubernetes namespace for Gateway API and Envoy Gateway"
  type        = string
  default     = "envoy-gateway-system"
}

variable "gateway_class_name" {
  description = "Name of the GatewayClass"
  type        = string
  default     = "envoy"
}
