data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Kubernetes Namespace
resource "kubernetes_namespace" "mongodb" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Generate random passwords
resource "random_password" "mongodb_password" {
  length  = 32
  special = false
}

# Create Kubernetes Secret for MongoDB credentials
resource "kubernetes_secret" "mongodb_admin_user" {
  metadata {
    name      = "mongodb-admin-user"
    namespace = kubernetes_namespace.mongodb.metadata[0].name
  }

  data = {
    password = random_password.mongodb_password.result
  }

  type = "Opaque"
}

# Install MongoDB Community Operator
resource "helm_release" "mongodb_operator" {
  namespace        = kubernetes_namespace.mongodb.metadata[0].name
  create_namespace = false
  name             = "mongodb-kubernetes-operator"
  repository       = "https://mongodb.github.io/helm-charts"
  chart            = "community-operator"
  version          = var.operator_version

  set {
    name  = "operator.watchNamespace"
    value = kubernetes_namespace.mongodb.metadata[0].name
  }

  depends_on = [
    kubernetes_namespace.mongodb
  ]
}

# Create gp3 StorageClass
resource "kubernetes_manifest" "storage_class_gp3" {
  manifest = yamldecode(file("${path.module}/manifests/storageclass-gp3.yaml"))
}

# Deploy MongoDB ReplicaSet using Community Operator CRD
resource "kubernetes_manifest" "mongodb_replicaset" {
  manifest = yamldecode(templatefile("${path.module}/manifests/mongodb-replicaset.yaml", {
    namespace         = kubernetes_namespace.mongodb.metadata[0].name
    replicas          = var.replicas
    mongodb_version   = var.mongodb_version
    admin_secret_name = kubernetes_secret.mongodb_admin_user.metadata[0].name
    storage_size      = var.storage_size
  }))

  depends_on = [
    helm_release.mongodb_operator,
    kubernetes_secret.mongodb_admin_user,
    kubernetes_manifest.storage_class_gp3
  ]
}
