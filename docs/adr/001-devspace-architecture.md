# ADR-001: DevSpace Architecture for Full-Stack Development

**Status:** Accepted  
**Date:** 2024-01-13  
**Deciders:** Architecture Team  

## Context and Problem Statement

We need to migrate from a Docker Compose-based development environment to a cloud-native Kubernetes setup that:

1. Provides development-production parity
2. Allows selective component replacement during development
3. Supports individual component development workflows
4. Maintains simplicity and developer experience
5. Prepares for future Helm chart migration

The current Docker Compose setup works locally but doesn't reflect production Kubernetes deployment patterns, making it difficult to catch environment-specific issues early in development.

## Decision Drivers

- **Development-Production Parity**: Minimize differences between dev and prod environments
- **Component Isolation**: Enable focused development on individual services
- **Developer Experience**: Maintain fast development cycles with hot reload
- **Resource Efficiency**: Avoid running unnecessary services during component-specific work
- **Production Readiness**: Use production-equivalent configurations and patterns
- **Future Migration**: Structure for easy conversion to Helm charts

## Considered Options

### Option 1: Single DevSpace Configuration
- **Pros**: Simple, single configuration file, easy to understand
- **Cons**: Cannot develop components in isolation, all-or-nothing deployment

### Option 2: Multiple DevSpace Configurations (Chosen)
- **Pros**: Component isolation, selective development, resource efficiency
- **Cons**: Multiple configuration files to maintain, potential duplication

### Option 3: Skaffold
- **Pros**: Google-maintained, good Kubernetes integration
- **Cons**: Less flexible than DevSpace, steeper learning curve

### Option 4: Tilt
- **Pros**: Good for complex microservices, powerful UI
- **Cons**: Additional complexity, requires learning new tooling

## Decision

We will implement **Option 2: Multiple DevSpace Configurations** with the following structure:

### Configuration Files
1. `devspace.yaml` - Main configuration for full-stack deployment
2. `devspace-backend.yaml` - Backend-specific development
3. `devspace-frontend.yaml` - Frontend-specific development  
4. `devspace-database.yaml` - Database-specific development

### Kubernetes Manifest Organization
```
k8s/base/
├── backend/        # FastAPI backend resources
├── frontend/       # React frontend resources  
├── database/       # PostgreSQL database resources
└── shared/         # ConfigMaps, Secrets, Ingress
```

### Development Workflows

#### Component-Specific Development
```bash
# Backend development with database running in cluster
devspace dev --config devspace-backend.yaml

# Frontend development with backend + database in cluster
devspace dev --config devspace-frontend.yaml

# Database development with admin tools
devspace dev --config devspace-database.yaml
```

#### Integration Testing
```bash
# Full stack deployment for integration testing
devspace deploy
```

## Architecture Principles

### 1. Pod Replacement Strategy
DevSpace replaces production pods with development versions instead of using sidecar containers:

**Benefits:**
- Identical production environment
- Resource efficiency
- No container orchestration complexity
- True development-production parity

**Trade-offs:**
- Longer startup times during development
- Container rebuilds required for major changes

### 2. Service Discovery
Components communicate using Kubernetes DNS:
- Backend connects to `postgres-service:5432`
- Frontend API calls route through ingress to `backend-service:8000`
- Maintains production networking patterns

### 3. Configuration Management
- **ConfigMaps**: Non-sensitive configuration (domains, CORS origins, database names)
- **Secrets**: Sensitive data (passwords, API keys, certificates)
- **Environment-specific**: Separate configs for dev/staging/production

### 4. Resource Isolation
Each component runs in separate pods:
- **Database Pod**: PostgreSQL with persistent storage
- **Backend Pod**: FastAPI with init container for migrations
- **Frontend Pod**: React app served by Nginx

## Implementation Details

### Database Strategy
- **Development**: Local PVC with PostgreSQL 17
- **Production**: Managed database service recommended
- **Persistence**: PersistentVolumeClaim for data durability
- **Admin Tools**: Adminer for development environments

### Backend Development
- **Hot Reload**: File sync with `fastapi dev` command
- **Migrations**: Automatic via init container
- **Debugging**: Terminal access and port forwarding
- **Dependencies**: uv package manager for fast installs

### Frontend Development  
- **Development Server**: Node.js dev server with HMR
- **Production Build**: Multi-stage Docker build with Nginx
- **API Integration**: Environment-based API URL configuration
- **Asset Optimization**: Build-time optimization for production

### Networking
- **Ingress**: NGINX Ingress Controller
- **Internal**: ClusterIP services for pod-to-pod communication  
- **External**: Port forwarding for development access
- **SSL**: Cert-manager integration for production TLS

## Consequences

### Positive
- **Development-Production Parity**: Catch environment issues early
- **Component Isolation**: Focused development without unnecessary overhead
- **Resource Efficiency**: Only run components being actively developed
- **Production Readiness**: Direct path from development to production deployment
- **Scalability**: Easy to add new services following the same pattern
- **Helm Migration**: Structure supports future Helm chart conversion

### Negative
- **Complexity**: More configuration files to maintain than Docker Compose
- **Learning Curve**: Developers need Kubernetes and DevSpace knowledge  
- **Startup Time**: Initial pod replacement takes longer than Docker container start
- **Configuration Duplication**: Some overlap between different DevSpace configs

### Neutral
- **Tool Dependency**: Requires DevSpace CLI installation and maintenance
- **Cluster Requirement**: Needs local or remote Kubernetes cluster
- **Resource Usage**: Similar to Docker Compose but distributed across pods

## Monitoring and Observability

Future enhancements will include:
- Prometheus metrics collection
- Grafana dashboards for development insights
- Distributed tracing with Jaeger
- Centralized logging with Loki

## Migration Path

### Phase 1: Current Implementation ✅
- DevSpace configurations
- Kubernetes base manifests
- Development workflows

### Phase 2: Production Hardening
- Helm chart conversion
- Security policies
- Resource quotas and limits
- Monitoring integration

### Phase 3: Advanced Features  
- Multi-environment support
- GitOps integration
- Automated testing pipelines
- Performance optimization

## Alternatives Reconsidered

We may revisit this decision if:
- DevSpace project becomes unmaintained
- Team grows significantly (>10 developers)
- Performance issues with pod replacement strategy
- Kubernetes complexity becomes prohibitive

## References

- [DevSpace Documentation](https://devspace.sh/cli/docs)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Twelve-Factor App Methodology](https://12factor.net/)
- [Docker Compose to Kubernetes Migration Guide](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/)