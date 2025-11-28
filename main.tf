locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name    = var.project_name
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  cluster_name    = var.cluster_name
  tags            = local.common_tags
}

# EKS Module - includes managed node groups for Karpenter and CoreDNS
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  tags               = local.common_tags

  depends_on = [module.vpc]
}

# Karpenter Module - deployed on managed nodes
module "karpenter" {
  count  = var.enable_karpenter ? 1 : 0
  source = "./modules/karpenter"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  oidc_provider_arn      = module.eks.oidc_provider_arn
  node_security_group_id = module.eks.node_security_group_id
  tags                   = local.common_tags

  depends_on = [module.eks]
}

# AWS Load Balancer Controller Module
module "aws_load_balancer_controller" {
  count  = var.enable_aws_load_balancer_controller ? 1 : 0
  source = "./modules/aws-load-balancer-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  vpc_id            = module.vpc.vpc_id
  tags              = local.common_tags

  depends_on = [module.eks]
}

# Cert Manager Module
module "cert_manager" {
  count  = var.enable_cert_manager ? 1 : 0
  source = "./modules/cert-manager"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  tags              = local.common_tags

  depends_on = [module.eks]
}

# External DNS Module
module "external_dns" {
  count  = var.enable_external_dns ? 1 : 0
  source = "./modules/external-dns"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  domain_name       = var.domain_name
  route53_zone_id   = var.route53_zone_id
  tags              = local.common_tags

  depends_on = [module.eks]
}

# Gateway API Module with Envoy
module "gateway_api" {
  count  = var.enable_gateway_api ? 1 : 0
  source = "./modules/gateway-api"

  cluster_name = module.eks.cluster_name
  tags         = local.common_tags

  depends_on = [
    module.eks,
    module.cert_manager
  ]
}

# MongoDB Module
module "mongodb" {
  count  = var.enable_mongodb ? 1 : 0
  source = "./modules/mongodb"

  cluster_name          = module.eks.cluster_name
  oidc_provider_arn     = module.eks.oidc_provider_arn
  namespace             = "mongodb"
  storage_size          = var.mongodb_storage_size
  replicas              = var.mongodb_replicas
  mongodb_version       = var.mongodb_version
  backup_schedule       = var.mongodb_backup_schedule
  backup_retention_days = var.mongodb_backup_retention_days
  tags                  = local.common_tags

  depends_on = [module.eks]
}

# Gatekeeper Module - Policy enforcement and governance
module "gatekeeper" {
  count  = var.enable_gatekeeper ? 1 : 0
  source = "./modules/gatekeeper"

  cluster_name = module.eks.cluster_name
  tags         = local.common_tags

  depends_on = [module.eks]
}

# Metrics Server Module - Container resource metrics for HPA and kubectl top
module "metrics_server" {
  count  = var.enable_metrics_server ? 1 : 0
  source = "./modules/metrics-server"

  cluster_name = module.eks.cluster_name
  tags         = local.common_tags

  depends_on = [module.eks]
}
