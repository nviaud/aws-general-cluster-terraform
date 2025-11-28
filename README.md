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
- **Gatekeeper**: OPA-based policy enforcement and governance for cluster security
- **Metrics Server**: Resource metrics for Horizontal Pod Autoscaler and kubectl top

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
    ├── mongodb/                     # MongoDB replica set
    ├── gatekeeper/                  # OPA Gatekeeper for policy enforcement
    └── metrics-server/              # Metrics Server for resource metrics
```

## Prerequisites

### For AWS Deployments (dev/staging/prod)

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5
3. **kubectl** for Kubernetes cluster access
4. **Helm** (optional, for manual chart management)
5. **Route53 Hosted Zone** for your domain (for External DNS)

### For Local Development (LocalStack)

1. **Docker** and **Docker Compose**
2. **Terraform** >= 1.5
3. See [LOCALSTACK.md](LOCALSTACK.md) for complete local setup

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

# Check Gatekeeper
kubectl get pods -n gatekeeper-system
kubectl get constrainttemplates
kubectl get constraints

# Check Metrics Server
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
kubectl top nodes
kubectl top pods -A
```

## Environment Management

This project supports multiple environments (dev, staging, prod) with separate state files and configurations.

### Environment Structure

```
environments/
├── dev.tfvars              # Development configuration
├── staging.tfvars          # Staging configuration
├── prod.tfvars             # Production configuration
├── backend-dev.hcl         # Dev backend config
├── backend-staging.hcl     # Staging backend config
└── backend-prod.hcl        # Production backend config
```

### Environment-Specific Settings

Each environment has different configurations:

**Local (LocalStack)**:
- No AWS costs - runs locally in Docker
- Minimal resource sizes
- Limited service support (VPC, S3, IAM basics)
- EKS/Kubernetes features disabled (requires LocalStack Pro)
- CIDR: 10.99.0.0/16
- See [LOCALSTACK.md](LOCALSTACK.md) for detailed setup

**Development (dev)**:
- Smaller resource sizes (10Gi MongoDB storage, 1 replica)
- Shorter backup retention (7 days)
- All features enabled for testing
- CIDR: 10.0.0.0/16
- Region: eu-west-1
- Domain: dev.example.com

**Staging (staging)**:
- Medium resource sizes (30Gi MongoDB storage, 2 replicas)
- Medium backup retention (14 days)
- Production-like configuration
- CIDR: 10.1.0.0/16
- Region: eu-west-1
- Domain: staging.example.com

**Production (prod)**:
- Large resource sizes (100Gi MongoDB storage, 3 replicas)
- Extended backup retention (90 days)
- High availability configuration
- CIDR: 10.2.0.0/16
- Region: eu-west-1
- Domain: example.com

### Using the Makefile

The project includes a Makefile for easy environment management:

```bash
# Show available commands
make help

# Initialize a specific environment
make init ENV=dev
make init ENV=staging
make init ENV=prod

# Plan changes for an environment
make plan ENV=dev

# Apply changes (includes confirmation for prod)
make apply ENV=staging

# View outputs
make output ENV=prod

# Destroy an environment (requires confirmation)
make destroy ENV=dev

# Shortcuts for specific environments
make dev-plan
make staging-apply
make prod-init

# Get kubeconfig for an environment
make kubeconfig-dev
make kubeconfig-staging
make kubeconfig-prod

# LocalStack (local development without AWS costs)
make local-setup        # Start LocalStack and setup environment
make local-init         # Initialize Terraform for local env
make local-plan         # Plan changes locally
make local-apply        # Apply changes to LocalStack
make local-clean        # Complete cleanup of local environment
```

For detailed LocalStack usage, see [LOCALSTACK.md](LOCALSTACK.md).

### Manual Environment Management

If you prefer not to use the Makefile:

**Initialize with environment-specific backend:**

```bash
terraform init -backend-config=environments/backend-dev.hcl -reconfigure
```

**Plan with environment-specific variables:**

```bash
terraform plan -var-file=environments/dev.tfvars
```

**Apply with environment-specific variables:**

```bash
terraform apply -var-file=environments/staging.tfvars
```

### First-Time Setup

1. **Set up the backend infrastructure** (S3 bucket and DynamoDB table):

```bash
make setup-backend
# or manually:
cd backend-setup
terraform init
terraform apply
cd ..
```

2. **Customize environment configurations**:

Edit `environments/dev.tfvars`, `environments/staging.tfvars`, and `environments/prod.tfvars` with your specific values:
- AWS region
- Domain names and Route53 zone IDs
- Resource sizing
- Feature flags

3. **Initialize and deploy each environment**:

```bash
# Development
make dev-init
make dev-plan
make dev-apply

# Staging
make staging-init
make staging-plan
make staging-apply

# Production
make prod-init
make prod-plan
make prod-apply
```

### Best Practices

1. **State Isolation**: Each environment has its own state file in S3 to prevent accidental changes
2. **Non-overlapping CIDRs**: Each environment uses different VPC CIDR blocks (10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16)
3. **Resource Naming**: Resources are named with environment prefix (e.g., cde-dev-eks, cde-prod-eks)
4. **Progressive Deployment**: Always test changes in dev → staging → prod
5. **Production Protection**: The Makefile includes additional confirmation prompts for production changes
6. **Separate AWS Accounts** (recommended): Consider using separate AWS accounts for production

### Switching Between Environments

To work with a different environment:

```bash
# Re-initialize with the target environment's backend
make init ENV=staging

# Now all terraform commands will use staging's state
terraform plan -var-file=environments/staging.tfvars
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
enable_gatekeeper                   = true
enable_metrics_server               = true
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

## Gatekeeper Policy Enforcement

Gatekeeper provides policy-as-code enforcement using Open Policy Agent (OPA). It validates and enforces policies on Kubernetes resources before they are created.

### Pre-configured Policies

The module includes five security policies enabled by default:

1. **Required Labels** (`K8sRequiredLabels`):
   - Enforces required labels on resources
   - Default required labels: `app`, `environment`
   - Validates label values against regex patterns
   - Applies to: Namespaces, Pods, Deployments, StatefulSets, DaemonSets

2. **Block Privileged Containers** (`K8sPSPPrivilegedContainer`):
   - Prevents containers from running in privileged mode
   - Blocks both containers and initContainers
   - Applies to: Pods

3. **Allowed Container Registries** (`K8sAllowedRepos`):
   - Restricts container images to approved registries
   - Default allowed: `public.ecr.aws/`, `ghcr.io/`, `quay.io/`, `docker.io/library/`
   - Applies to: Pods (containers and initContainers)

4. **Container Resource Limits** (`K8sContainerLimits`):
   - Requires CPU and memory limits on all containers
   - Prevents resource exhaustion
   - Applies to: Pods

5. **Block Host Namespaces** (`K8sPSPHostNamespace`):
   - Prevents use of hostNetwork, hostPID, hostIPC
   - Reduces attack surface
   - Applies to: Pods

### Excluded Namespaces

The following namespaces are excluded from Gatekeeper policies by default:
- `kube-system`
- `kube-public`
- `kube-node-lease`
- `gatekeeper-system`
- `karpenter`

### Viewing Gatekeeper Status

**Check installed constraint templates:**

```bash
kubectl get constrainttemplates
```

**Check active constraints:**

```bash
kubectl get constraints
```

**View policy violations in audit mode:**

```bash
kubectl get constraints -o yaml | grep -A 10 violations
```

**Check Gatekeeper logs:**

```bash
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -f
```

### Customizing Policies

Policies can be customized in your environment `.tfvars` files:

**Disable specific policies:**

```hcl
enable_required_labels            = false
enable_privileged_container_check = false
enable_allowed_repos              = false
enable_container_limits           = false
enable_host_namespace_check       = false
```

**Customize allowed registries:**

```hcl
allowed_repos = [
  "your-account.dkr.ecr.eu-west-1.amazonaws.com/",
  "ghcr.io/your-org/",
]
```

**Customize required labels:**

```hcl
required_labels = [
  {
    key          = "team"
    allowedRegex = "^(platform|data|ml)$"
  },
  {
    key          = "cost-center"
    allowedRegex = ""
  }
]
```

**Add custom namespaces to exclusion list:**

```hcl
excluded_namespaces = [
  "kube-system",
  "gatekeeper-system",
  "your-critical-namespace",
]
```

### Testing Policies

**Test blocking privileged containers:**

```bash
kubectl run privileged-test --image=nginx --privileged=true
# Should be rejected by Gatekeeper
```

**Test required labels:**

```bash
kubectl run test-pod --image=nginx
# Should be rejected for missing required labels

kubectl run test-pod --image=nginx --labels="app=test,environment=dev"
# Should be allowed
```

**Test container limits:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-limits
  labels:
    app: test
    environment: dev
spec:
  containers:
  - name: nginx
    image: nginx
    # Missing resource limits - should be rejected
```

### Webhook Configuration

The validating webhook is configured with `webhook_failure_policy = "Ignore"` by default, meaning:
- If Gatekeeper is unavailable, requests are allowed
- Set to `"Fail"` in production for stricter enforcement

Configure in your `.tfvars`:

```hcl
webhook_failure_policy = "Fail"  # Reject all requests if Gatekeeper is down
```

## Metrics Server

Metrics Server collects resource metrics from Kubelets and exposes them via the Metrics API for use by Horizontal Pod Autoscaler (HPA) and the `kubectl top` command.

### Features

- **Resource Metrics**: Provides CPU and memory metrics for nodes and pods
- **HPA Support**: Required for Horizontal Pod Autoscaler to function
- **kubectl top**: Enables `kubectl top nodes` and `kubectl top pods` commands
- **High Availability**: Runs 2 replicas by default for reliability
- **System Node Placement**: Configured to run on system nodes with appropriate tolerations

### Using Metrics Server

**Check node resource usage:**

```bash
kubectl top nodes
```

**Check pod resource usage:**

```bash
kubectl top pods -A
kubectl top pods -n <namespace>
```

**Create a Horizontal Pod Autoscaler:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

**Or using kubectl:**

```bash
kubectl autoscale deployment myapp --cpu-percent=70 --min=2 --max=10
```

### Verify Metrics Server

**Check if Metrics Server is running:**

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server
```

**Test metrics API:**

```bash
kubectl get apiservices | grep metrics
# Should show: v1beta1.metrics.k8s.io
```

**Check logs:**

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=metrics-server -f
```

### Configuration

Metrics Server is configured with:
- **Metric resolution**: 15 seconds (default)
- **Replicas**: 2 for high availability
- **Priority class**: system-cluster-critical
- **Resource limits**: 200m CPU, 256Mi memory
- **Resource requests**: 100m CPU, 128Mi memory

These can be customized by modifying `modules/metrics-server/variables.tf`.

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

### Gatekeeper issues

**Check if Gatekeeper is running:**

```bash
kubectl get pods -n gatekeeper-system
kubectl logs -n gatekeeper-system -l control-plane=controller-manager -f
```

**Check if constraints are enforced:**

```bash
kubectl get constrainttemplates
kubectl get constraints
```

**Debug policy violations:**

```bash
# Check constraint status for violations
kubectl get constraints -o yaml

# Test a policy
kubectl run test --image=nginx --dry-run=server
```

**Webhook not blocking resources:**

- Verify webhook is configured: `kubectl get validatingwebhookconfigurations`
- Check if namespace is excluded from policies
- Verify constraint template and constraint are created
- Check Gatekeeper audit logs for violations

### Metrics Server issues

**kubectl top not working:**

```bash
# Check if Metrics Server is running
kubectl get pods -n kube-system -l app.kubernetes.io/name=metrics-server

# Check Metrics Server logs
kubectl logs -n kube-system -l app.kubernetes.io/name=metrics-server -f

# Verify metrics API is registered
kubectl get apiservices | grep metrics
```

**Common issues:**

- **Metrics not available yet**: Wait 15-30 seconds after pod starts for first metrics collection
- **TLS errors**: Metrics Server is configured with proper kubelet communication settings
- **No metrics for nodes**: Check that kubelet is exposing metrics on the node

**Test metrics API directly:**

```bash
kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
```

## Security Considerations

- All EBS volumes are encrypted
- MongoDB uses authentication
- IRSA (IAM Roles for Service Accounts) for secure AWS API access
- Security groups properly configured
- Private subnets for worker nodes
- Managed node groups use IMDSv2
- Gatekeeper enforces security policies (privileged containers, host namespaces, resource limits)
- Policy-as-code approach for consistent security enforcement
- Admission control prevents non-compliant resources from being created

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
- [ ] Review and customize Gatekeeper policies for your security requirements
- [ ] Set webhook_failure_policy to "Fail" for stricter enforcement
- [ ] Test Gatekeeper policies in non-production environments first
- [ ] Customize allowed container registries to match your organization's registries
- [ ] Configure required labels to match your tagging strategy

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
