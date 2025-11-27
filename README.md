# EKS Infrastructure with Application Components

This Terraform project provisions a production-ready Amazon EKS cluster with essential application components using a well-decoupled modular architecture.

**Uses only official HashiCorp providers** (AWS, Kubernetes, Helm) - no third-party dependencies.

## Architecture Overview

The infrastructure includes:

- **VPC Module**: Multi-AZ VPC with public/private subnets, NAT gateways, and proper tagging for EKS
- **EKS Module**: EKS cluster with managed node groups for system components (Karpenter and CoreDNS)
- **Karpenter**: Auto-scaling solution running on managed nodes
- **AWS Load Balancer Controller**: Manages ALB/NLB for Kubernetes Ingress
- **Cert Manager**: Automated certificate management
- **External DNS**: Automated DNS management with Route53
- **Gateway API with Envoy Proxy**: Modern ingress solution with Envoy Gateway
- **MongoDB**: Replica set deployment for data persistence

## Module Structure

```
.
├── main.tf                          # Root module orchestration
├── variables.tf                     # Root module variables
├── outputs.tf                       # Root module outputs
├── providers.tf                     # Provider configurations
├── versions.tf                      # Terraform and provider versions
├── terraform.tfvars.example         # Example configuration
└── modules/
    ├── vpc/                         # VPC and networking
    ├── eks/                         # EKS cluster with managed nodes
    ├── karpenter/                   # Karpenter auto-scaler
    ├── aws-load-balancer-controller/# AWS Load Balancer Controller
    ├── cert-manager/                # Certificate management
    ├── external-dns/                # DNS management
    ├── gateway-api/                 # Gateway API with Envoy
    └── mongodb/                     # MongoDB replica set
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5
3. **kubectl** for Kubernetes cluster access
4. **Helm** (optional, for manual chart management)
5. **Route53 Hosted Zone** for your domain (for External DNS)

## Quick Start

### 1. Configure Variables

Copy the example configuration and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

- `aws_region`: Your AWS region
- `cluster_name`: Unique name for your EKS cluster
- `domain_name`: Your domain name (must have Route53 hosted zone)
- `route53_zone_id`: Route53 hosted zone ID
- Other configuration as needed

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

This will provision:
- VPC with public/private subnets across 3 AZs
- EKS cluster with managed node groups
- All application components

The deployment typically takes 15-20 minutes.

### 5. Configure kubectl

After the deployment completes, configure kubectl to access your cluster:

```bash
aws eks update-kubeconfig --region <aws-region> --name <cluster-name>
```

Or use the output command:

```bash
terraform output -raw configure_kubectl | bash
```

### 6. Verify the Deployment

Check that all components are running:

```bash
# Check nodes
kubectl get nodes

# Check Karpenter
kubectl get pods -n karpenter

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check Cert Manager
kubectl get pods -n cert-manager

# Check External DNS
kubectl get pods -n external-dns

# Check Gateway API
kubectl get pods -n envoy-gateway-system
kubectl get gateway -n envoy-gateway-system

# Check MongoDB
kubectl get pods -n mongodb
```

## Key Features

### Managed Nodes for System Components

The EKS cluster includes a managed node group specifically for system components (Karpenter and CoreDNS):

- **Taints**: `CriticalAddonsOnly=true:NoSchedule`
- **Labels**: `role=system`
- **Instance Types**: Configurable (default: t3.medium)
- **Auto-scaling**: 2-4 nodes

This ensures that Karpenter and CoreDNS run on stable, managed infrastructure while Karpenter dynamically provisions additional nodes for application workloads.

### Karpenter Configuration

Karpenter is pre-configured with:

- Default NodePool for on-demand and spot instances
- EC2NodeClass with AL2 AMI
- Automatic interruption handling via SQS and EventBridge
- Proper IAM roles and security groups

### Gateway API with Envoy

The Gateway API module deploys:

- Gateway API CRDs (v1.0.0)
- Envoy Gateway controller
- Default GatewayClass and Gateway
- NLB service type for internet-facing traffic

### MongoDB with Community Operator

MongoDB is deployed using the **MongoDB Community Operator** as a 3-node replica set with:

- MongoDB Community Operator for production-grade deployments
- Custom Resource Definitions (CRDs) for declarative management
- Persistent storage using EBS gp3 volumes
- SCRAM authentication enabled
- Automatic password generation
- **Automated S3 Backups** via CronJob (daily at 2 AM UTC by default)
- S3 bucket with versioning and lifecycle policies
- IRSA (IAM Roles for Service Accounts) for secure S3 access
- Configurable backup schedule and retention period

## Module Configuration

Each module is independently configurable through the root module. You can enable/disable components using feature flags:

```hcl
enable_karpenter                    = true
enable_aws_load_balancer_controller = true
enable_cert_manager                 = true
enable_external_dns                 = true
enable_gateway_api                  = true
enable_mongodb                      = true
```

## Accessing MongoDB

### Get MongoDB Credentials

To get the MongoDB admin password:

```bash
terraform output -raw mongodb_admin_password
```

To get the full connection string:

```bash
terraform output -raw mongodb_connection_string
```

### Connect to MongoDB

To connect to MongoDB from within the cluster:

```bash
kubectl run -it --rm mongo-client --image=mongo:7.0.5 --restart=Never -n mongodb -- \
  mongosh "mongodb://admin:<password>@mongodb-replica-set-0.mongodb-replica-set-svc.mongodb.svc.cluster.local:27017,mongodb-replica-set-1.mongodb-replica-set-svc.mongodb.svc.cluster.local:27017,mongodb-replica-set-2.mongodb-replica-set-svc.mongodb.svc.cluster.local:27017/?replicaSet=mongodb-replica-set"
```

### MongoDB Backups

Backups are automatically created according to the configured schedule (default: daily at 2 AM UTC).

**View backup jobs:**

```bash
kubectl get cronjobs -n mongodb
kubectl get jobs -n mongodb
```

**View backup logs:**

```bash
kubectl logs -n mongodb -l job-name=mongodb-backup-<timestamp>
```

**List backups in S3:**

```bash
aws s3 ls s3://$(terraform output -raw mongodb_s3_backup_bucket)/
```

**Manually trigger a backup:**

```bash
kubectl create job -n mongodb --from=cronjob/mongodb-backup mongodb-backup-manual-$(date +%s)
```

**Restore from backup:**

```bash
# Download backup from S3
aws s3 cp s3://$(terraform output -raw mongodb_s3_backup_bucket)/mongodb-backup-<timestamp>.tar.gz .

# Extract backup
tar -xzf mongodb-backup-<timestamp>.tar.gz

# Restore to MongoDB
kubectl run -it --rm mongo-restore --image=mongo:7.0.5 --restart=Never -n mongodb -- \
  mongorestore --host mongodb-replica-set-svc.mongodb.svc.cluster.local \
    --username admin --password <password> \
    --authenticationDatabase admin \
    /path/to/backup
```

## Using the Gateway API

To create an HTTPRoute:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
  namespace: default
spec:
  parentRefs:
  - name: default-gateway
    namespace: envoy-gateway-system
  hostnames:
  - "example.yourdomain.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: example-service
      port: 80
```

External DNS will automatically create the DNS record.

## Customization

### Adding Custom Node Groups

You can modify the EKS module to add more managed node groups or adjust the system node group configuration in `modules/eks/variables.tf`.

### Karpenter NodePools

Create custom NodePools by adding kubectl manifests to the Karpenter module or applying them separately after deployment.

### MongoDB Configuration

Adjust MongoDB settings in `variables.tf` or your `.tfvars` file:

- **MongoDB version** (`mongodb_version`): MongoDB version to deploy
- **Storage size** (`mongodb_storage_size`): Persistent volume size per replica
- **Replica count** (`mongodb_replicas`): Number of MongoDB replicas (default: 3)
- **Backup schedule** (`mongodb_backup_schedule`): Cron schedule for backups (default: daily at 2 AM)
- **Backup retention** (`mongodb_backup_retention_days`): Days to keep backups in S3 (default: 30)
- Resource requests/limits can be adjusted in `modules/mongodb/main.tf`

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including persistent volumes. Make sure to backup any important data first.

## Cost Optimization

To reduce costs:

1. Adjust managed node group sizes in `modules/eks/variables.tf`
2. Use spot instances for Karpenter-managed nodes
3. Reduce MongoDB replica count for dev environments
4. Disable unused components via feature flags

## Troubleshooting

### Karpenter not scheduling pods

Check the Karpenter logs:

```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f
```

Verify the NodePool and EC2NodeClass:

```bash
kubectl get nodepools
kubectl get ec2nodeclasses
```

### AWS Load Balancer Controller issues

Check the controller logs:

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f
```

Verify IAM role annotations:

```bash
kubectl describe sa -n kube-system aws-load-balancer-controller
```

### External DNS not creating records

Check External DNS logs:

```bash
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns -f
```

Verify IAM permissions for Route53.

### Gateway API issues

Check Envoy Gateway logs:

```bash
kubectl logs -n envoy-gateway-system -l control-plane=envoy-gateway -f
```

Verify Gateway status:

```bash
kubectl describe gateway -n envoy-gateway-system default-gateway
```

## Security Considerations

- All EBS volumes are encrypted
- MongoDB uses authentication
- IRSA (IAM Roles for Service Accounts) for secure AWS API access
- Security groups properly configured
- Private subnets for worker nodes
- Managed node groups use IMDSv2

## Production Readiness Checklist

Before going to production:

- [ ] Review and adjust resource requests/limits
- [ ] Configure cluster autoscaler limits
- [ ] Set up monitoring and alerting
- [ ] Configure backup solutions for MongoDB
- [ ] Review security group rules
- [ ] Enable additional EKS logging
- [ ] Configure pod security policies/standards
- [ ] Set up disaster recovery procedures
- [ ] Review and adjust cost optimization settings
- [ ] Configure TLS certificates for Gateway API

## Contributing

This is a modular infrastructure project. Each module is independent and can be:

- Used separately
- Extended with additional features
- Customized for specific requirements

## License

This project is provided as-is for infrastructure provisioning purposes.

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review Terraform plan output
3. Check AWS CloudWatch logs
4. Review Kubernetes events and pod logs
