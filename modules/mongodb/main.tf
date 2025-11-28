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
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "gp3"
    }
    provisioner = "ebs.csi.aws.com"
    parameters = {
      type       = "gp3"
      encrypted  = "true"
      iops       = "3000"
      throughput = "125"
    }
    volumeBindingMode    = "WaitForFirstConsumer"
    allowVolumeExpansion = true
    reclaimPolicy        = "Delete"
  }
}

# Deploy MongoDB ReplicaSet using Community Operator CRD
resource "kubernetes_manifest" "mongodb_replicaset" {
  manifest = {
    apiVersion = "mongodbcommunity.mongodb.com/v1"
    kind       = "MongoDBCommunity"
    metadata = {
      name      = "mongodb-replica-set"
      namespace = kubernetes_namespace.mongodb.metadata[0].name
    }
    spec = {
      members = var.replicas
      type    = "ReplicaSet"
      version = var.mongodb_version
      security = {
        authentication = {
          modes = ["SCRAM"]
        }
      }
      users = [
        {
          name = "admin"
          db   = "admin"
          passwordSecretRef = {
            name = kubernetes_secret.mongodb_admin_user.metadata[0].name
          }
          roles = [
            {
              name = "clusterAdmin"
              db   = "admin"
            },
            {
              name = "userAdminAnyDatabase"
              db   = "admin"
            },
            {
              name = "dbAdminAnyDatabase"
              db   = "admin"
            },
            {
              name = "readWriteAnyDatabase"
              db   = "admin"
            }
          ]
          scramCredentialsSecretName = "mongodb-admin-scram"
        }
      ]
      statefulSet = {
        spec = {
          volumeClaimTemplates = [
            {
              metadata = {
                name = "data-volume"
              }
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.storage_size
                  }
                }
              }
            },
            {
              metadata = {
                name = "logs-volume"
              }
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "2Gi"
                  }
                }
              }
            }
          ]
          template = {
            spec = {
              containers = [
                {
                  name = "mongod"
                  resources = {
                    limits = {
                      cpu    = "1000m"
                      memory = "2Gi"
                    }
                    requests = {
                      cpu    = "250m"
                      memory = "512Mi"
                    }
                  }
                },
                {
                  name = "mongodb-agent"
                  resources = {
                    limits = {
                      cpu    = "500m"
                      memory = "512Mi"
                    }
                    requests = {
                      cpu    = "100m"
                      memory = "256Mi"
                    }
                  }
                }
              ]
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.mongodb_operator,
    kubernetes_secret.mongodb_admin_user,
    kubernetes_manifest.storage_class_gp3
  ]
}
