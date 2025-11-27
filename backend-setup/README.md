# Terraform Backend Setup

This directory contains the Terraform configuration to create the S3 bucket and DynamoDB table for storing the main project's Terraform state.

## Why Separate Backend Setup?

The backend resources (S3 bucket and DynamoDB table) are managed separately from the main infrastructure to:

1. Prevent circular dependencies (backend must exist before main project can use it)
2. Allow backend resources to be managed independently
3. Reduce risk of accidental state loss
4. Follow infrastructure best practices

## Resources Created

1. **S3 Bucket** (`<project-name>-<environment>-terraform-state`)
   - Versioning enabled for state history
   - Server-side encryption (AES256)
   - Public access blocked
   - Lifecycle policy to delete old versions after 90 days
   - SSL-only access enforced

2. **DynamoDB Table** (`<project-name>-<environment>-terraform-locks`)
   - Used for state locking to prevent concurrent modifications
   - Pay-per-request billing mode
   - Hash key: `LockID`

## Setup Instructions

### Step 1: Configure Variables

Copy the example tfvars file and customize it:

```bash
cd backend-setup
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region   = "us-west-2"
project_name = "cde-infra"
environment  = "prod"

tags = {
  Project     = "CDE Infrastructure"
  ManagedBy   = "Terraform"
  Environment = "prod"
}
```

### Step 2: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Create the backend resources
terraform apply
```

After successful apply, you'll see output with the S3 bucket name and DynamoDB table name.

### Step 3: Note the Output

Save the output values - you'll need them for the next step:

```bash
terraform output
```

Example output:
```
s3_bucket_name       = "cde-infra-prod-terraform-state"
dynamodb_table_name  = "cde-infra-prod-terraform-locks"
backend_config       = "..."
```

### Step 4: Update Main Project

Go to the main project's `versions.tf` and uncomment the backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "cde-infra-prod-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "cde-infra-prod-terraform-locks"
    encrypt        = true
  }
}
```

Replace the placeholder values with the actual values from the backend-setup output.

### Step 5: Migrate State to S3

From your main project directory:

```bash
# Initialize with the new backend configuration
terraform init -migrate-state

# Terraform will prompt: "Do you want to copy existing state to the new backend?"
# Type: yes
```

Your state is now stored in S3!

### Step 6: Verify Migration

Check that your state is in S3:

```bash
aws s3 ls s3://cde-infra-prod-terraform-state/

# You should see: terraform.tfstate
```

You can also verify in the AWS Console:
- S3 Console: Check the bucket contents
- DynamoDB Console: Check the locks table (should be empty when no operations are running)

## State Management

### Viewing State

```bash
# List resources in state
terraform state list

# Show a specific resource
terraform state show <resource-name>
```

### Backing Up State

S3 versioning is enabled, but you can also manually backup:

```bash
# Download current state
aws s3 cp s3://cde-infra-prod-terraform-state/terraform.tfstate ./backup-$(date +%Y%m%d).tfstate
```

### Restoring Previous State Version

If needed, you can restore a previous version from S3:

```bash
# List versions
aws s3api list-object-versions --bucket cde-infra-prod-terraform-state --prefix terraform.tfstate

# Download a specific version
aws s3api get-object --bucket cde-infra-prod-terraform-state --key terraform.tfstate --version-id <version-id> restored-state.tfstate
```

## State Locking

The DynamoDB table prevents concurrent Terraform operations:

- When you run `terraform apply`, a lock is acquired
- If another user tries to run Terraform, they'll get a lock error
- Lock is automatically released when operation completes
- If Terraform crashes, you may need to manually remove the lock:

```bash
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

## Multi-Environment Setup

For multiple environments (dev, staging, prod), you have two options:

### Option 1: Separate Backends per Environment

Run this backend-setup for each environment with different tfvars:

```bash
# dev environment
terraform apply -var="environment=dev"

# prod environment
terraform apply -var="environment=prod"
```

### Option 2: Use Workspaces (Not Recommended for Production)

Terraform workspaces can share the same backend but are not recommended for production use.

## Security Considerations

- **State contains secrets**: The Terraform state file contains sensitive data (passwords, connection strings)
- **Access Control**: Ensure only authorized users have access to the S3 bucket
- **Encryption**: State is encrypted at rest in S3
- **SSL/TLS**: Only HTTPS connections are allowed to the bucket
- **IAM Policies**: Use least-privilege IAM policies for accessing the backend

## Troubleshooting

### Error: Backend configuration changed

If you modify the backend configuration, run:

```bash
terraform init -reconfigure
```

### Error: Failed to acquire state lock

Someone else is running Terraform, or a previous run crashed:

```bash
# Wait for the other operation to complete, or if it crashed:
terraform force-unlock <lock-id>
```

### Error: Access Denied to S3 bucket

Check your AWS credentials and IAM permissions:

```bash
aws sts get-caller-identity
aws s3 ls s3://cde-infra-prod-terraform-state/
```

## Cleanup

**WARNING**: Only delete backend resources if you're completely decommissioning the infrastructure.

To destroy the backend resources:

```bash
# Make sure you've backed up your state!
terraform destroy
```

This will delete the S3 bucket and DynamoDB table. Your main infrastructure will lose access to its state file.

## Additional Resources

- [Terraform S3 Backend Documentation](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [State Locking Documentation](https://www.terraform.io/docs/language/state/locking.html)
- [AWS S3 Versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
