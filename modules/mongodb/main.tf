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

# S3 Bucket for MongoDB Backups
resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "${var.cluster_name}-mongodb-backups"

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-mongodb-backups"
      Purpose = "MongoDB Backups"
    }
  )
}

resource "aws_s3_bucket_versioning" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "mongodb_backups" {
  bucket = aws_s3_bucket.mongodb_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for MongoDB Backup (IRSA)
resource "aws_iam_role" "mongodb_backup" {
  name = "${var.cluster_name}-mongodb-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:${var.namespace}:mongodb-backup"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "mongodb_backup" {
  name        = "${var.cluster_name}-mongodb-backup"
  description = "IAM policy for MongoDB backup to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.mongodb_backups.arn,
          "${aws_s3_bucket.mongodb_backups.arn}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "mongodb_backup" {
  role       = aws_iam_role.mongodb_backup.name
  policy_arn = aws_iam_policy.mongodb_backup.arn
}

# Service Account for MongoDB Backup
resource "kubernetes_service_account" "mongodb_backup" {
  metadata {
    name      = "mongodb-backup"
    namespace = kubernetes_namespace.mongodb.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.mongodb_backup.arn
    }
  }
}

# ConfigMap for Backup Script
resource "kubernetes_config_map" "mongodb_backup_script" {
  metadata {
    name      = "mongodb-backup-script"
    namespace = kubernetes_namespace.mongodb.metadata[0].name
  }

  data = {
    "backup.sh" = <<-EOF
      #!/bin/bash
      set -e

      TIMESTAMP=$(date +%Y%m%d_%H%M%S)
      BACKUP_NAME="mongodb-backup-$TIMESTAMP"
      BACKUP_DIR="/tmp/$BACKUP_NAME"
      S3_BUCKET="${aws_s3_bucket.mongodb_backups.bucket}"
      S3_PATH="s3://$S3_BUCKET/$BACKUP_NAME"

      echo "Starting MongoDB backup at $TIMESTAMP"

      # Get MongoDB connection details
      MONGODB_HOST="mongodb-replica-set-svc.${var.namespace}.svc.cluster.local"
      MONGODB_USERNAME="admin"
      MONGODB_PASSWORD=$(cat /mongodb-secret/password)

      # Create backup directory
      mkdir -p $BACKUP_DIR

      # Run mongodump
      mongodump \
        --host="$MONGODB_HOST" \
        --username="$MONGODB_USERNAME" \
        --password="$MONGODB_PASSWORD" \
        --authenticationDatabase=admin \
        --out=$BACKUP_DIR

      # Compress backup
      cd /tmp
      tar -czf $BACKUP_NAME.tar.gz $BACKUP_NAME

      # Upload to S3
      echo "Uploading backup to S3..."
      aws s3 cp $BACKUP_NAME.tar.gz $S3_PATH.tar.gz

      # Cleanup
      rm -rf $BACKUP_DIR $BACKUP_NAME.tar.gz

      echo "Backup completed successfully and uploaded to $S3_PATH.tar.gz"
    EOF
  }
}

# CronJob for MongoDB Backups
resource "kubernetes_manifest" "mongodb_backup_cronjob" {
  manifest = {
    apiVersion = "batch/v1"
    kind       = "CronJob"
    metadata = {
      name      = "mongodb-backup"
      namespace = kubernetes_namespace.mongodb.metadata[0].name
    }
    spec = {
      schedule                   = var.backup_schedule
      successfulJobsHistoryLimit = 3
      failedJobsHistoryLimit     = 3
      jobTemplate = {
        spec = {
          template = {
            spec = {
              serviceAccountName = kubernetes_service_account.mongodb_backup.metadata[0].name
              restartPolicy      = "OnFailure"
              containers = [
                {
                  name  = "mongodb-backup"
                  image = "mongo:${var.mongodb_version}"
                  command = ["/bin/bash", "/scripts/backup.sh"]
                  env = [
                    {
                      name  = "AWS_REGION"
                      value = data.aws_region.current.name
                    }
                  ]
                  volumeMounts = [
                    {
                      name      = "backup-script"
                      mountPath = "/scripts"
                    },
                    {
                      name      = "mongodb-secret"
                      mountPath = "/mongodb-secret"
                      readOnly  = true
                    }
                  ]
                  resources = {
                    limits = {
                      cpu    = "500m"
                      memory = "1Gi"
                    }
                    requests = {
                      cpu    = "250m"
                      memory = "512Mi"
                    }
                  }
                }
              ]
              volumes = [
                {
                  name = "backup-script"
                  configMap = {
                    name        = kubernetes_config_map.mongodb_backup_script.metadata[0].name
                    defaultMode = 0755
                  }
                },
                {
                  name = "mongodb-secret"
                  secret = {
                    secretName = kubernetes_secret.mongodb_admin_user.metadata[0].name
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
    kubernetes_manifest.mongodb_replicaset,
    kubernetes_service_account.mongodb_backup,
    kubernetes_config_map.mongodb_backup_script
  ]
}
