# Full-Stack DevSpace Architecture Overview

## System Context (C4 Level 1)

```mermaid
graph TB
    subgraph "External Systems"
        USER[User<br/>Developer/End User]
        REGISTRY[Container Registry<br/>Docker Hub/ECR]
        EMAIL[Email Service<br/>SMTP Provider]
        MONITORING[Monitoring<br/>Sentry/DataDog]
    end
    
    subgraph "Development Environment"
        DEVSPACE[DevSpace CLI<br/>Local Development Tool]
    end
    
    subgraph "Kubernetes Cluster"
        FULLSTACK[Full-Stack Application<br/>FastAPI + React + PostgreSQL]
    end
    
    USER --> FULLSTACK
    USER --> DEVSPACE
    DEVSPACE --> FULLSTACK
    FULLSTACK --> EMAIL
    FULLSTACK --> MONITORING
    DEVSPACE -.-> REGISTRY
    
    style FULLSTACK fill:#e1f5fe
    style DEVSPACE fill:#f3e5f5
    style USER fill:#e8f5e8
```

## Container Architecture (C4 Level 2)

```mermaid
graph TB
    subgraph "Browser"
        BROWSER[Web Browser<br/>React SPA]
    end
    
    subgraph "Kubernetes Cluster"
        subgraph "Frontend Pod"
            REACT[React Application<br/>Port 80]
            NGINX[Nginx<br/>Web Server]
        end
        
        subgraph "Backend Pod"
            FASTAPI[FastAPI Application<br/>Port 8000]
            PYTHON[Python Runtime<br/>uv Package Manager]
        end
        
        subgraph "Database Pod"
            POSTGRES[PostgreSQL 17<br/>Port 5432]
            PGDATA[Persistent Storage<br/>PVC Mount]
        end
        
        subgraph "Admin Tools (Dev Only)"
            ADMINER[Adminer<br/>Database Admin<br/>Port 8080]
        end
        
        subgraph "Networking"
            INGRESS[NGINX Ingress<br/>External Access]
            FRONTEND_SVC[frontend-service<br/>ClusterIP:80]
            BACKEND_SVC[backend-service<br/>ClusterIP:8000]
            DATABASE_SVC[postgres-service<br/>ClusterIP:5432]
        end
    end
    
    BROWSER --> INGRESS
    INGRESS --> FRONTEND_SVC
    INGRESS --> BACKEND_SVC
    FRONTEND_SVC --> NGINX
    NGINX --> REACT
    BACKEND_SVC --> FASTAPI
    FASTAPI --> PYTHON
    FASTAPI --> DATABASE_SVC
    DATABASE_SVC --> POSTGRES
    POSTGRES --> PGDATA
    ADMINER --> DATABASE_SVC
    
    style REACT fill:#61dafb
    style FASTAPI fill:#009688
    style POSTGRES fill:#336791
    style INGRESS fill:#ff6b6b
```

## Development Workflow (C4 Level 3)

```mermaid
graph TB
    subgraph "Developer Machine"
        DEV[Developer]
        VSCODE[VS Code<br/>Local IDE]
        DEVSPACE_CLI[DevSpace CLI<br/>v6.3.0+]
        KUBECTL[kubectl<br/>Kubernetes CLI]
        DOCKER[Docker<br/>Container Runtime]
    end
    
    subgraph "Source Code"
        BACKEND_CODE[Backend Code<br/>./backend/]
        FRONTEND_CODE[Frontend Code<br/>./frontend/]
        K8S_MANIFESTS[K8s Manifests<br/>./k8s/base/]
        DEVSPACE_CONFIGS[DevSpace Configs<br/>devspace-*.yaml]
    end
    
    subgraph "Kubernetes Cluster"
        subgraph "Pod Replacement Strategy"
            DEV_BACKEND[Development Backend Pod<br/>Hot Reload Enabled]
            DEV_FRONTEND[Development Frontend Pod<br/>React Dev Server]
            DEV_DATABASE[Development Database Pod<br/>Debug Mode + Adminer]
        end
        
        subgraph "Production-like Pods"
            PROD_BACKEND[Production Backend Pod<br/>FastAPI + uv]
            PROD_FRONTEND[Production Frontend Pod<br/>React + Nginx]
            PROD_DATABASE[Production Database Pod<br/>PostgreSQL]
        end
    end
    
    DEV --> VSCODE
    VSCODE --> BACKEND_CODE
    VSCODE --> FRONTEND_CODE
    
    DEV --> DEVSPACE_CLI
    DEVSPACE_CLI --> DEVSPACE_CONFIGS
    DEVSPACE_CLI --> K8S_MANIFESTS
    DEVSPACE_CLI --> KUBECTL
    DEVSPACE_CLI --> DOCKER
    
    DEVSPACE_CLI -.->|Pod Replacement| DEV_BACKEND
    DEVSPACE_CLI -.->|Pod Replacement| DEV_FRONTEND
    DEVSPACE_CLI -.->|Pod Replacement| DEV_DATABASE
    
    DEVSPACE_CLI -->|File Sync| DEV_BACKEND
    DEVSPACE_CLI -->|File Sync| DEV_FRONTEND
    
    DEV_BACKEND -.->|Fallback| PROD_BACKEND
    DEV_FRONTEND -.->|Fallback| PROD_FRONTEND
    DEV_DATABASE -.->|Fallback| PROD_DATABASE
    
    style DEV_BACKEND fill:#4caf50
    style DEV_FRONTEND fill:#2196f3
    style DEV_DATABASE fill:#ff9800
    style DEVSPACE_CLI fill:#9c27b0
```

## Component Interaction Sequence

```mermaid
sequenceDiagram
    participant D as Developer
    participant DS as DevSpace CLI
    participant K as Kubernetes
    participant BE as Backend Pod
    participant FE as Frontend Pod
    participant DB as Database Pod
    
    Note over D,DB: Backend Development Workflow
    
    D->>DS: devspace dev --config devspace-backend.yaml
    DS->>K: Deploy database and frontend pods
    DS->>K: Replace backend pod with dev version
    DS->>BE: Sync local code changes
    DS->>BE: Enable hot reload
    DS->>D: Port forward :8000
    
    loop Development Cycle
        D->>DS: Edit backend code
        DS->>BE: Sync file changes
        BE->>BE: Auto-reload application
        D->>BE: Test API endpoints
    end
    
    Note over D,DB: Frontend Development Workflow
    
    D->>DS: devspace dev --config devspace-frontend.yaml
    DS->>K: Deploy backend and database pods
    DS->>K: Replace frontend pod with dev version
    DS->>FE: Start React dev server
    DS->>FE: Sync local code changes
    DS->>D: Port forward :3000
    
    loop Development Cycle
        D->>DS: Edit frontend code
        DS->>FE: Sync file changes
        FE->>FE: Hot module replacement
        FE->>BE: API calls via service discovery
        D->>FE: Test in browser
    end
    
    Note over D,DB: Database Development Workflow
    
    D->>DS: devspace dev --config devspace-database.yaml
    DS->>K: Deploy database pod with admin tools
    DS->>DB: Enable debug logging
    DS->>D: Port forward :5432 (DB) and :8080 (Adminer)
    
    D->>DB: Run migrations
    D->>DB: Database administration
    D->>DS: Access Adminer web interface
```

## Configuration Strategy

### ConfigMap Hierarchy
```mermaid
graph TB
    subgraph "Configuration Management"
        BASE_CONFIG[Base ConfigMap<br/>app-config]
        DEV_CONFIG[Development ConfigMap<br/>app-config-dev]
        PROD_CONFIG[Production ConfigMap<br/>app-config-production]
        
        SECRETS[Secrets<br/>app-secrets]
        DEV_SECRETS[Development Secrets<br/>Base64 encoded]
        PROD_SECRETS[Production Secrets<br/>External Secret Manager]
    end
    
    subgraph "Environment Variables"
        DOMAIN[DOMAIN]
        CORS_ORIGINS[BACKEND_CORS_ORIGINS]
        DB_CONFIG[Database Configuration]
        SMTP_CONFIG[SMTP Configuration]
        MONITORING_CONFIG[Monitoring Configuration]
    end
    
    BASE_CONFIG --> DEV_CONFIG
    BASE_CONFIG --> PROD_CONFIG
    
    DEV_CONFIG --> DOMAIN
    DEV_CONFIG --> CORS_ORIGINS
    DEV_CONFIG --> DB_CONFIG
    
    SECRETS --> DEV_SECRETS
    SECRETS --> PROD_SECRETS
    
    DEV_SECRETS --> DB_CONFIG
    DEV_SECRETS --> SMTP_CONFIG
    PROD_SECRETS --> MONITORING_CONFIG
    
    style BASE_CONFIG fill:#e3f2fd
    style DEV_CONFIG fill:#f3e5f5  
    style PROD_CONFIG fill:#fff3e0
    style SECRETS fill:#ffebee
```

## Deployment Strategies

### Development Deployment
```mermaid
flowchart LR
    subgraph "Local Development"
        CODE[Source Code<br/>Changes]
        BUILD[Container Build<br/>Local Docker]
        DEPLOY[Pod Replacement<br/>DevSpace]
    end
    
    subgraph "Kubernetes Cluster"
        DEV_PODS[Development Pods<br/>Hot Reload Enabled]
        SERVICES[Kubernetes Services<br/>ClusterIP]
        INGRESS[Local Ingress<br/>*.localhost]
    end
    
    CODE --> BUILD
    BUILD --> DEPLOY
    DEPLOY --> DEV_PODS
    DEV_PODS --> SERVICES
    SERVICES --> INGRESS
    
    style DEV_PODS fill:#4caf50
    style BUILD fill:#ff9800
```

### Production Deployment
```mermaid
flowchart LR
    subgraph "CI/CD Pipeline"
        GIT[Git Repository<br/>main branch]
        CI[GitHub Actions<br/>GitLab CI]
        REGISTRY[Container Registry<br/>Push Images]
    end
    
    subgraph "Production Cluster"
        PROD_PODS[Production Pods<br/>Optimized Images]
        LB[Load Balancer<br/>External Access]
        TLS[TLS Certificates<br/>cert-manager]
    end
    
    GIT --> CI
    CI --> REGISTRY
    REGISTRY --> PROD_PODS
    PROD_PODS --> LB
    LB --> TLS
    
    style PROD_PODS fill:#2196f3
    style CI fill:#4caf50
    style TLS fill:#ff5722
```

## Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        subgraph "Network Security"
            INGRESS_TLS[TLS Termination<br/>Ingress Controller]
            NETWORK_POLICIES[Network Policies<br/>Pod-to-Pod Communication]
            SERVICE_MESH[Service Mesh<br/>mTLS (Optional)]
        end
        
        subgraph "Authentication & Authorization"
            JWT[JWT Tokens<br/>FastAPI Security]
            RBAC[RBAC<br/>Kubernetes]
            SERVICE_ACCOUNTS[Service Accounts<br/>Pod Identity]
        end
        
        subgraph "Secrets Management"
            K8S_SECRETS[Kubernetes Secrets<br/>Base64 Encoded]
            EXTERNAL_SECRETS[External Secrets<br/>Vault/AWS/Azure]
            SECRET_ROTATION[Secret Rotation<br/>Automated]
        end
        
        subgraph "Container Security"
            IMAGE_SCANNING[Image Scanning<br/>Trivy/Snyk]
            DISTROLESS[Distroless Images<br/>Minimal Attack Surface]
            SECURITY_CONTEXTS[Security Contexts<br/>Non-root User]
        end
    end
    
    INGRESS_TLS --> JWT
    NETWORK_POLICIES --> RBAC
    JWT --> K8S_SECRETS
    RBAC --> SERVICE_ACCOUNTS
    K8S_SECRETS --> EXTERNAL_SECRETS
    EXTERNAL_SECRETS --> SECRET_ROTATION
    
    IMAGE_SCANNING --> DISTROLESS
    DISTROLESS --> SECURITY_CONTEXTS
    
    style INGRESS_TLS fill:#4caf50
    style JWT fill:#2196f3
    style EXTERNAL_SECRETS fill:#ff9800
    style IMAGE_SCANNING fill:#9c27b0
```

## Monitoring and Observability

```mermaid
graph TB
    subgraph "Application Metrics"
        FASTAPI_METRICS[FastAPI Metrics<br/>Prometheus Endpoint]
        REACT_METRICS[React Metrics<br/>Web Vitals]
        DB_METRICS[PostgreSQL Metrics<br/>pg_stat_*]
    end
    
    subgraph "Infrastructure Metrics"
        K8S_METRICS[Kubernetes Metrics<br/>kube-state-metrics]
        NODE_METRICS[Node Metrics<br/>node-exporter]
        CONTAINER_METRICS[Container Metrics<br/>cAdvisor]
    end
    
    subgraph "Observability Stack"
        PROMETHEUS[Prometheus<br/>Metrics Collection]
        GRAFANA[Grafana<br/>Visualization]
        LOKI[Loki<br/>Log Aggregation]
        JAEGER[Jaeger<br/>Distributed Tracing]
    end
    
    subgraph "Alerting"
        ALERTMANAGER[Alertmanager<br/>Alert Routing]
        SLACK[Slack<br/>Notifications]
        PAGERDUTY[PagerDuty<br/>Incident Management]
    end
    
    FASTAPI_METRICS --> PROMETHEUS
    REACT_METRICS --> PROMETHEUS
    DB_METRICS --> PROMETHEUS
    
    K8S_METRICS --> PROMETHEUS
    NODE_METRICS --> PROMETHEUS
    CONTAINER_METRICS --> PROMETHEUS
    
    PROMETHEUS --> GRAFANA
    PROMETHEUS --> ALERTMANAGER
    
    ALERTMANAGER --> SLACK
    ALERTMANAGER --> PAGERDUTY
    
    style PROMETHEUS fill:#e6522c
    style GRAFANA fill:#f46800
    style LOKI fill:#f4b942
    style JAEGER fill:#60d0e4
```

## Future Architecture Evolution

### Phase 1: Current State ✅
- DevSpace configurations
- Kubernetes base manifests  
- Development workflows
- Basic monitoring

### Phase 2: Production Hardening
- Helm chart conversion
- Advanced security policies
- Multi-environment support
- GitOps integration

### Phase 3: Platform Engineering
- Developer platform abstractions
- Self-service environments
- Advanced observability
- Cost optimization

### Phase 4: Cloud Native Maturity
- Service mesh integration
- Advanced deployment strategies
- AI/ML pipeline integration
- Multi-cluster operations

## Key Architectural Decisions

1. **Pod Replacement over Sidecars**: Maintains production parity
2. **Component Isolation**: Independent development workflows
3. **Kubernetes-Native**: Direct mapping to production patterns
4. **Configuration as Code**: GitOps-ready manifest structure
5. **Developer Experience**: Minimal cognitive load for common tasks

This architecture provides a solid foundation for cloud-native full-stack development while maintaining the flexibility to evolve with changing requirements and team growth.