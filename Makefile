# Makefile

PYTHON      ?= python3
PIP         ?= pip
RUFF        ?= ruff
MYPY        ?= mypy
BANDIT      ?= bandit
TEST_DIRS   = tests
PYTEST      ?= pytest

# Where your Python code lives
SRC_DIRS    = services utils tests

# ---------------- Terraform & Lambdas ----------------

.PHONY: terraform_apply
terraform_apply:
	@echo "Applying Terraform in ./terraform..."
	terraform -chdir=./terraform init -input=false
	terraform -chdir=./terraform apply -auto-approve

.PHONY: build_lambdas
build_lambdas:
	@echo "Building Lambda functions..."
	bash scripts/build_lambdas.sh

.PHONY: deploy_all
deploy_all: build_lambdas terraform_apply
	@echo "Deployment finished!"

# ---------------- Dev tools install ----------------

.PHONY: install_dev
install_dev:
	@echo "Installing dev tools (ruff, mypy, bandit)..."
	$(PIP) install ruff mypy bandit

# ---------------- Code quality ----------------

# Ruff lint (no formatting)
.PHONY: lint
lint:
	@echo "Running Ruff (lint only)..."
	$(RUFF) check $(SRC_DIRS)

# Ruff as formatter
.PHONY: format
format:
	@echo "Running Ruff formatter..."
	$(RUFF) format $(SRC_DIRS)

# mypy type checking
.PHONY: typecheck
typecheck:
	@echo "Running mypy..."
	$(MYPY) $(SRC_DIRS)

# Security scan
.PHONY: security
security:
	@echo "Running Bandit security checks..."
	$(BANDIT) -r services utils

# Everything in one go
.PHONY: check
check: lint typecheck security
	@echo "All checks passed!"

.PHONY: lint_fix
lint_fix:
	@echo "Running Ruff (auto-fix)..."
	$(RUFF) check --fix $(SRC_DIRS)

.PHONY: test
test:
	@echo "Running tests..."
	$(PYTEST) $(TEST_DIRS)