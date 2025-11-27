bucket         = "cde-terraform-state"
key            = "environments/prod/terraform.tfstate"
region         = "eu-west-1"
encrypt        = true
dynamodb_table = "cde-terraform-locks"
