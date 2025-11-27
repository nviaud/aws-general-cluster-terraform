# Local backend configuration
# For LocalStack, we use local file-based state instead of S3
# The state file will be stored at: ./terraform.tfstate.d/local/terraform.tfstate

# Note: This file is used with terraform init for consistency with other environments,
# but since it's empty, Terraform will use the default local backend
