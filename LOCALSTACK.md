# LocalStack Development Environment

This guide explains how to use LocalStack for local development and testing of your infrastructure without incurring AWS costs.

## What is LocalStack?

LocalStack is a cloud service emulator that runs in a single container on your machine. It provides a local testing environment that emulates AWS cloud services, allowing you to develop and test cloud applications offline.

## Prerequisites

1. **Docker** - Required to run LocalStack container
2. **Docker Compose** - For easy container management
3. **Terraform** >= 1.5
4. **curl** - For health checks (optional)
5. **awslocal** CLI (optional but recommended):
   ```bash
   pip install awscli-local
   ```

## Important Limitations

**LocalStack Community Edition has limitations:**

- **EKS Support**: Limited/Pro feature only
- **Kubernetes Resources**: Helm, Karpenter, and K8s components won't work
- **Most modules disabled**: The local.tfvars disables most modules by default

**What works in Community Edition:**
- ✅ VPC and networking (EC2, subnets, route tables, NAT gateways, IGW)
- ✅ S3 buckets
- ✅ IAM roles and policies (basic)
- ✅ DynamoDB
- ✅ Route53 (basic)
- ✅ Security Groups
- ✅ Elastic IPs

**What doesn't work:**
- ❌ EKS clusters
- ❌ Kubernetes/Helm resources
- ❌ EKS add-ons

**For full EKS testing**, you would need:
- LocalStack Pro (paid)
- OR use a real AWS dev account with the dev.tfvars configuration

## VPC-Only Testing (Recommended for LocalStack Community)

Since EKS requires LocalStack Pro, the recommended approach is to test VPC infrastructure only:

### Successfully Tested Resources

The following VPC resources work perfectly in LocalStack Community:

```bash
# Apply will create VPC resources and fail on EKS (expected)
terraform apply -var-file=environments/local.tfvars -auto-approve

# VPC resources successfully created:
# ✅ VPC (10.99.0.0/16)
# ✅ 2 Public Subnets
# ✅ 2 Private Subnets
# ✅ Internet Gateway
# ✅ 2 NAT Gateways
# ✅ 2 Elastic IPs
# ✅ Route Tables & Associations
# ✅ Security Groups (cluster & node)
# ✅ IAM Roles & Policies
# ✅ Launch Templates

# ❌ EKS Cluster will fail (requires Pro)
```

### View Created Resources

```bash
# Show all VPC resources
terraform state list | grep module.vpc

# Show VPC outputs
terraform output

# Show specific resource details
terraform state show module.vpc.aws_vpc.main
```

### Example Output

```
VPC Resources Created:
  - VPC: vpc-d66bc0bf4f9210041 (10.99.0.0/16)
  - Private Subnets: subnet-0266d8f2324555e39, subnet-180cac4a223e75e1b
  - Public Subnets: subnet-dc72295cce2c9ebf6, subnet-89588a26c4154ea4e
  - NAT Gateways: nat-cb47d21a8fcfd1b35, nat-b78930a8e4298cb14
  - Internet Gateway: igw-cc2a0efbc329a2c6b
```

## Quick Start

### 1. Start LocalStack

Start the LocalStack container:

```bash
make localstack-start
```

This will:
- Start LocalStack on port 4566
- Enable persistence (data survives container restarts)
- Wait for services to be ready

### 2. Verify LocalStack is Running

Check the health of LocalStack services:

```bash
make localstack-status
```

Or view logs:

```bash
make localstack-logs
```

### 3. Initialize Terraform for Local Environment

```bash
make local-init
```

This automatically:
- Creates `providers_override.tf` from the template
- Starts LocalStack if not already running
- Initializes Terraform with local backend

### 4. Plan and Apply

```bash
# Plan changes
make local-plan

# Apply infrastructure
make local-apply
```

Note: Most modules are disabled by default. To test specific modules, edit `environments/local.tfvars`.

## Manual Setup (Alternative)

If you prefer manual setup:

### 1. Start LocalStack

```bash
docker-compose up -d
```

### 2. Create Provider Override

```bash
cp providers_override.tf.local providers_override.tf
```

### 3. Initialize and Apply

```bash
terraform init -reconfigure
terraform plan -var-file=environments/local.tfvars
terraform apply -var-file=environments/local.tfvars
```

## Available Make Commands

### LocalStack Management
- `make localstack-start` - Start LocalStack container
- `make localstack-stop` - Stop LocalStack container
- `make localstack-restart` - Restart LocalStack
- `make localstack-logs` - View LocalStack logs
- `make localstack-status` - Check service health

### Local Environment
- `make local-setup` - Complete local environment setup
- `make local-init` - Initialize Terraform for local env
- `make local-plan` - Plan infrastructure changes
- `make local-apply` - Apply infrastructure changes
- `make local-destroy` - Destroy local infrastructure
- `make local-clean` - Complete cleanup (stops LocalStack, removes data)

## Using AWS CLI with LocalStack

### Option 1: Using awslocal (Recommended)

Install awslocal:
```bash
pip install awscli-local
```

Use it just like AWS CLI:
```bash
awslocal s3 ls
awslocal ec2 describe-vpcs
awslocal iam list-roles
```

### Option 2: Using AWS CLI with endpoint

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 ec2 describe-vpcs
```

### Option 3: Set environment variables

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws --endpoint-url=http://localhost:4566 s3 ls
```

## Configuration Files

### environments/local.tfvars
Contains the local environment configuration with:
- Minimal resource sizing
- Most modules disabled (due to LocalStack limitations)
- Local network ranges (10.99.0.0/16)

### providers_override.tf
(Auto-generated, not in git)
Overrides the AWS provider to use LocalStack endpoints instead of real AWS.

### docker-compose.yml
Defines the LocalStack container configuration:
- Port 4566 for all services
- Persistent data storage in `.localstack/`
- Health checks enabled

## Testing Individual Modules

To test specific modules with LocalStack:

1. Edit `environments/local.tfvars`
2. Set the feature flag to `true`:
   ```hcl
   enable_karpenter = true  # If supported by LocalStack
   ```
3. Apply changes:
   ```bash
   make local-apply
   ```

## Persistence

LocalStack data is persisted in `.localstack/` directory:
- Data survives container restarts
- Deleted when you run `make local-clean`
- Not committed to git (in .gitignore)

To start completely fresh:
```bash
make local-clean
make local-setup
```

## Troubleshooting

### LocalStack Not Starting

Check Docker is running:
```bash
docker ps
```

View LocalStack logs:
```bash
make localstack-logs
```

### Services Not Available

Check which services are running:
```bash
curl http://localhost:4566/_localstack/health
```

### Terraform Errors with LocalStack

1. Ensure `providers_override.tf` exists:
   ```bash
   ls -la providers_override.tf
   ```

2. Ensure LocalStack is running:
   ```bash
   make localstack-status
   ```

3. Check LocalStack logs for errors:
   ```bash
   make localstack-logs
   ```

### Port 4566 Already in Use

Check if another LocalStack instance is running:
```bash
docker ps | grep localstack
```

Stop it:
```bash
make localstack-stop
```

## Resource Limits

LocalStack Community Edition has service limitations. For production-like testing:

1. Use the `dev.tfvars` environment with real AWS (eu-west-1)
2. Or upgrade to LocalStack Pro for full EKS support

## Cleaning Up

### Remove VPC Resources Only
```bash
# Destroy only the successfully created VPC resources
terraform destroy -target=module.vpc -var-file=environments/local.tfvars -auto-approve
```

### Clean Failed EKS Resources from State
```bash
# If you have failed EKS resources in state, remove them
terraform state rm module.eks.aws_eks_cluster.main
```

### Soft Cleanup (Keep LocalStack Data)
```bash
terraform destroy -var-file=environments/local.tfvars
```

### Hard Cleanup (Remove Everything)
```bash
make local-clean
```

This removes:
- LocalStack container
- Persistent data (`.localstack/`)
- Provider overrides
- Terraform state files

### Fresh Start
```bash
# Complete cleanup and restart
make local-clean
make local-setup
terraform apply -var-file=environments/local.tfvars -auto-approve
```

## Cost Savings

Using LocalStack for development:
- No AWS costs for development
- Fast iteration without waiting for AWS provisioning
- Test infrastructure code without risk
- Safe to experiment and break things

For actual AWS resources testing, use the dev environment in eu-west-1.

## Next Steps

After validating your infrastructure code locally:

1. Test in dev environment:
   ```bash
   make dev-init
   make dev-plan
   make dev-apply
   ```

2. Promote to staging:
   ```bash
   make staging-init
   make staging-apply
   ```

3. Deploy to production:
   ```bash
   make prod-init
   make prod-apply
   ```

## Additional Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [LocalStack GitHub](https://github.com/localstack/localstack)
- [LocalStack Pro Features](https://localstack.cloud/pricing/)
