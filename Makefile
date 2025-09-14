.PHONY: help dev deploy clean logs shell migrate test build buildkit-setup buildkit-validate

# Default variables
DOMAIN ?= localhost
PROFILE ?= development
COMPONENT ?= all

# Enable BuildKit by default
export DOCKER_BUILDKIT=1

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# Development commands
dev: ## Start development environment (make dev COMPONENT=backend)
	@if [ "$(COMPONENT)" = "backend" ]; then \
		devspace dev --config devspace-backend.yaml; \
	elif [ "$(COMPONENT)" = "frontend" ]; then \
		devspace dev --config devspace-frontend.yaml; \
	elif [ "$(COMPONENT)" = "database" ]; then \
		devspace dev --config devspace-database.yaml; \
	else \
		devspace dev --profile $(COMPONENT)-dev; \
	fi

dev-backend: ## Start backend development
	devspace dev --config devspace-backend.yaml

dev-frontend: ## Start frontend development  
	devspace dev --config devspace-frontend.yaml

dev-database: ## Start database development
	devspace dev --config devspace-database.yaml

# Deployment commands
deploy: ## Deploy full stack (make deploy PROFILE=production DOMAIN=yourdomain.com)
	devspace deploy --profile $(PROFILE) --var DOMAIN=$(DOMAIN)

deploy-backend: ## Deploy only backend component
	devspace deploy --config devspace-backend.yaml --var DOMAIN=$(DOMAIN)

deploy-frontend: ## Deploy only frontend component
	devspace deploy --config devspace-frontend.yaml --var DOMAIN=$(DOMAIN)

deploy-database: ## Deploy only database component
	devspace deploy --config devspace-database.yaml

# Build commands
build: ## Build all container images
	devspace build

build-backend: ## Build backend image only
	devspace build --config devspace-backend.yaml

build-frontend: ## Build frontend image only
	devspace build --config devspace-frontend.yaml

# Operational commands
logs: ## View logs (make logs COMPONENT=backend)
	@if [ "$(COMPONENT)" = "backend" ]; then \
		devspace run logs-backend; \
	elif [ "$(COMPONENT)" = "frontend" ]; then \
		devspace run logs-frontend; \
	elif [ "$(COMPONENT)" = "database" ]; then \
		devspace run logs-database; \
	else \
		echo "Please specify COMPONENT (backend|frontend|database)"; \
	fi

shell: ## Get shell access (make shell COMPONENT=backend)
	@if [ "$(COMPONENT)" = "backend" ]; then \
		devspace run shell-backend; \
	elif [ "$(COMPONENT)" = "frontend" ]; then \
		devspace run shell-frontend; \
	elif [ "$(COMPONENT)" = "database" ]; then \
		devspace run shell-database; \
	else \
		echo "Please specify COMPONENT (backend|frontend|database)"; \
	fi

migrate: ## Run database migrations
	devspace run migrate

create-migration: ## Create new migration (make create-migration MSG="add user table")
	MIGRATION_MESSAGE="$(MSG)" devspace run create-migration

# Cleanup commands
clean: ## Clean up deployments
	devspace purge --all

clean-backend: ## Clean up backend deployment
	devspace purge --config devspace-backend.yaml

clean-frontend: ## Clean up frontend deployment  
	devspace purge --config devspace-frontend.yaml

clean-database: ## Clean up database deployment
	devspace purge --config devspace-database.yaml

# Testing commands
test-unit: ## Run unit tests
	@echo "Running unit tests..."
	cd backend && python -m pytest tests/unit/
	cd frontend && npm test

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	cd backend && python -m pytest tests/integration/

test-e2e: ## Run end-to-end tests
	@echo "Running E2E tests..."
	cd frontend && npm run test:e2e

# Kubernetes commands
k8s-status: ## Check Kubernetes status
	kubectl get all -l app=fullstack-app

k8s-describe: ## Describe all resources
	kubectl describe all -l app=fullstack-app

k8s-events: ## Show recent events
	kubectl get events --sort-by=.metadata.creationTimestamp

# Development utilities
format: ## Format code
	cd backend && ruff format .
	cd frontend && npm run format

lint: ## Lint code
	cd backend && ruff check .
	cd frontend && npm run lint

type-check: ## Run type checking
	cd backend && mypy .
	cd frontend && npm run type-check

# Security
security-scan: ## Scan for security vulnerabilities
	@echo "Scanning backend dependencies..."
	cd backend && safety check
	@echo "Scanning frontend dependencies..."
	cd frontend && npm audit

# Documentation
docs-serve: ## Serve documentation locally
	@if command -v mkdocs >/dev/null 2>&1; then \
		mkdocs serve; \
	else \
		echo "MkDocs not installed. Install with: pip install mkdocs"; \
	fi

# Production helpers
prod-deploy: ## Deploy to production
	$(MAKE) deploy PROFILE=production DOMAIN=$(DOMAIN)

prod-backup: ## Create production backup
	devspace deploy --config devspace-database.yaml --profile backup

prod-restore: ## Restore from backup (requires BACKUP_FILE)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "Please specify BACKUP_FILE"; \
		exit 1; \
	fi
	kubectl exec -i deployment/postgres-db -- psql -U postgres -d app < $(BACKUP_FILE)

# Quick commands for common operations
up: deploy ## Alias for deploy
down: clean ## Alias for clean
restart: clean deploy ## Restart all services

# Environment setup
setup-dev: ## Set up development environment
	@echo "Setting up development environment..."
	@command -v devspace >/dev/null 2>&1 || { echo "Please install DevSpace CLI first"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "Please install kubectl first"; exit 1; }
	@kubectl cluster-info >/dev/null 2>&1 || { echo "Please configure kubectl for your cluster"; exit 1; }
	@echo "✅ Development environment is ready!"

check-deps: ## Check if all dependencies are installed
	@echo "Checking dependencies..."
	@command -v devspace >/dev/null 2>&1 && echo "✅ DevSpace CLI" || echo "❌ DevSpace CLI"
	@command -v kubectl >/dev/null 2>&1 && echo "✅ kubectl" || echo "❌ kubectl"  
	@command -v docker >/dev/null 2>&1 && echo "✅ Docker" || echo "❌ Docker"
	@kubectl cluster-info >/dev/null 2>&1 && echo "✅ Kubernetes cluster" || echo "❌ Kubernetes cluster"

# BuildKit commands
buildkit-setup: ## Set up Docker BuildKit
	@echo "Setting up Docker BuildKit..."
	@echo "export DOCKER_BUILDKIT=1" >> ~/.bashrc || true
	@echo "export DOCKER_BUILDKIT=1" >> ~/.zshrc || true
	@echo "✅ DOCKER_BUILDKIT=1 added to shell profile"
	@echo "🔄 Please restart your shell or run: export DOCKER_BUILDKIT=1"

buildkit-validate: ## Validate BuildKit setup
	@echo "🔍 Validating BuildKit setup..."
	@./scripts/validate-buildkit.sh

buildkit-info: ## Show BuildKit build information
	@echo "📊 BuildKit Build Information:"
	@echo "Docker BuildKit enabled: $${DOCKER_BUILDKIT:-not set}"
	@docker buildx version 2>/dev/null && echo "✅ Docker Buildx available" || echo "❌ Docker Buildx not available"
	@docker system df --format "table {{.Type}}\t{{.Total}}\t{{.Active}}\t{{.Size}}\t{{.Reclaimable}}" | grep -E "(TYPE|buildcache)" || echo "No BuildKit cache found"

buildkit-clean: ## Clean BuildKit cache
	@echo "🧹 Cleaning BuildKit cache..."
	@docker builder prune -f
	@echo "✅ BuildKit cache cleaned"

buildkit-build: ## Build with verbose BuildKit output (make buildkit-build COMPONENT=backend)
	@echo "🔨 Building with BuildKit (verbose output)..."
	@if [ "$(COMPONENT)" = "backend" ]; then \
		devspace build --config devspace-backend.yaml --verbose; \
	elif [ "$(COMPONENT)" = "frontend" ]; then \
		devspace build --config devspace-frontend.yaml --verbose; \
	else \
		devspace build --verbose; \
	fi