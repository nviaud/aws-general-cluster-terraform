.PHONY: help init plan apply destroy validate fmt lint clean

# Default environment (can be overridden)
ENV ?= dev

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

help: ## Show this help message
	@echo 'Usage: make [target] ENV=[dev|staging|prod]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ''
	@echo 'Examples:'
	@echo '  make init ENV=dev         # Initialize dev environment'
	@echo '  make plan ENV=staging     # Plan staging changes'
	@echo '  make apply ENV=prod       # Apply production changes'

init: ## Initialize Terraform with environment-specific backend
	@echo "$(GREEN)Initializing Terraform for $(ENV) environment...$(NC)"
	terraform init -backend-config=environments/backend-$(ENV).hcl -reconfigure

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	terraform validate

fmt: ## Format Terraform files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

plan: ## Plan Terraform changes for the specified environment
	@echo "$(GREEN)Planning changes for $(ENV) environment...$(NC)"
	terraform plan -var-file=environments/$(ENV).tfvars -out=$(ENV).tfplan

apply: ## Apply Terraform changes for the specified environment
	@echo "$(YELLOW)Applying changes for $(ENV) environment...$(NC)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)WARNING: You are about to apply changes to PRODUCTION!$(NC)"; \
		read -p "Type 'yes' to continue: " confirm; \
		if [ "$$confirm" != "yes" ]; then \
			echo "$(RED)Aborted.$(NC)"; \
			exit 1; \
		fi; \
	fi
	terraform apply -var-file=environments/$(ENV).tfvars

apply-plan: ## Apply a saved plan file
	@echo "$(YELLOW)Applying saved plan for $(ENV) environment...$(NC)"
	terraform apply $(ENV).tfplan

destroy: ## Destroy Terraform-managed infrastructure
	@echo "$(RED)WARNING: You are about to destroy $(ENV) infrastructure!$(NC)"
	@read -p "Type 'yes' to continue: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "$(RED)Aborted.$(NC)"; \
		exit 1; \
	fi
	terraform destroy -var-file=environments/$(ENV).tfvars

output: ## Show Terraform outputs
	@echo "$(GREEN)Outputs for $(ENV) environment:$(NC)"
	terraform output

state-list: ## List resources in state
	@echo "$(GREEN)Resources in $(ENV) state:$(NC)"
	terraform state list

clean: ## Clean up generated files
	@echo "$(GREEN)Cleaning up generated files...$(NC)"
	rm -f *.tfplan
	rm -rf .terraform
	rm -f .terraform.lock.hcl

# Development shortcuts
dev-init: ## Initialize dev environment
	@$(MAKE) init ENV=dev

dev-plan: ## Plan dev environment
	@$(MAKE) plan ENV=dev

dev-apply: ## Apply dev environment
	@$(MAKE) apply ENV=dev

# Staging shortcuts
staging-init: ## Initialize staging environment
	@$(MAKE) init ENV=staging

staging-plan: ## Plan staging environment
	@$(MAKE) plan ENV=staging

staging-apply: ## Apply staging environment
	@$(MAKE) apply ENV=staging

# Production shortcuts
prod-init: ## Initialize prod environment
	@$(MAKE) init ENV=prod

prod-plan: ## Plan prod environment
	@$(MAKE) plan ENV=prod

prod-apply: ## Apply prod environment
	@$(MAKE) apply ENV=prod

# Setup backend (run this first)
setup-backend: ## Setup S3 backend and DynamoDB table
	@echo "$(GREEN)Setting up backend infrastructure...$(NC)"
	cd backend-setup && terraform init && terraform apply

# Kubeconfig shortcuts
kubeconfig-dev: ## Get kubeconfig for dev
	@aws eks update-kubeconfig --region eu-west-1 --name cde-dev-eks

kubeconfig-staging: ## Get kubeconfig for staging
	@aws eks update-kubeconfig --region eu-west-1 --name cde-staging-eks

kubeconfig-prod: ## Get kubeconfig for prod
	@aws eks update-kubeconfig --region eu-west-1 --name cde-prod-eks

# LocalStack targets
localstack-start: ## Start LocalStack container
	@echo "$(GREEN)Starting LocalStack...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Waiting for LocalStack to be ready...$(NC)"
	@sleep 5
	@echo "$(GREEN)LocalStack is ready at http://localhost:4566$(NC)"

localstack-stop: ## Stop LocalStack container
	@echo "$(YELLOW)Stopping LocalStack...$(NC)"
	docker-compose down

localstack-restart: ## Restart LocalStack container
	@$(MAKE) localstack-stop
	@$(MAKE) localstack-start

localstack-logs: ## View LocalStack logs
	docker-compose logs -f localstack

localstack-status: ## Check LocalStack status
	@echo "$(GREEN)Checking LocalStack health...$(NC)"
	@curl -s http://localhost:4566/_localstack/health | python -m json.tool || echo "$(RED)LocalStack is not running$(NC)"

local-setup: ## Setup local environment with LocalStack
	@echo "$(GREEN)Setting up local environment...$(NC)"
	@if [ ! -f providers_override.tf ]; then \
		echo "$(YELLOW)Creating providers_override.tf from template...$(NC)"; \
		cp providers_override.tf.local providers_override.tf; \
	fi
	@$(MAKE) localstack-start
	@echo "$(GREEN)Local environment is ready!$(NC)"

local-init: local-setup ## Initialize Terraform for local environment
	@echo "$(GREEN)Initializing Terraform for local environment...$(NC)"
	terraform init -reconfigure

local-plan: ## Plan changes for local environment
	@echo "$(GREEN)Planning changes for local environment...$(NC)"
	terraform plan -var-file=environments/local.tfvars

local-apply: ## Apply changes to local environment
	@echo "$(YELLOW)Applying changes to local environment...$(NC)"
	terraform apply -var-file=environments/local.tfvars

local-destroy: ## Destroy local environment resources
	@echo "$(RED)Destroying local environment resources...$(NC)"
	terraform destroy -var-file=environments/local.tfvars

local-clean: ## Clean local environment completely
	@echo "$(RED)Cleaning local environment...$(NC)"
	@$(MAKE) localstack-stop
	@rm -rf .localstack
	@rm -f providers_override.tf
	@rm -f terraform.tfstate terraform.tfstate.backup
	@echo "$(GREEN)Local environment cleaned!$(NC)"
