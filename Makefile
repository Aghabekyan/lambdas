# Makefile

# Target: apply Terraform
.PHONY: terraform_apply
terraform_apply:
	@echo "Applying Terraform in ./terraform..."
	terraform -chdir=./terraform apply -auto-approve

# Target: build Lambdas
.PHONY: build_lambdas
build_lambdas:
	@echo "Building Lambda functions..."
	bash scripts/build_lambdas.sh

# Optional: a single command to do both
.PHONY: deploy_all
deploy_all: build_lambdas terraform_apply
	@echo "Deployment finished!"
