# BuildKit Setup for DevSpace

This project is optimized to use Docker BuildKit for faster, more efficient builds with advanced caching strategies.

## Prerequisites

### 1. Enable BuildKit

Ensure BuildKit is enabled in your Docker environment:

```bash
# Set environment variable
export DOCKER_BUILDKIT=1

# Or add to your shell profile (~/.bashrc, ~/.zshrc)
echo "export DOCKER_BUILDKIT=1" >> ~/.bashrc
```

### 2. Docker Buildx (Optional but Recommended)

For advanced BuildKit features:

```bash
# Check if buildx is available
docker buildx version

# Create a new builder instance (optional)
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
```

## BuildKit Features Used

### 1. Cache Mounts

Both Dockerfiles use cache mounts to speed up dependency installation:

**Backend (Python/uv):**
```dockerfile
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project
```

**Frontend (Node.js/npm):**
```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci --cache /root/.npm --prefer-offline
```

### 2. Registry Caching

DevSpace configurations use registry-based caching for better CI/CD support:

```yaml
buildKit:
  enable: true
  args:
    - --cache-to=type=registry,ref=fastapi-backend:buildcache,mode=max
    - --cache-from=type=registry,ref=fastapi-backend:buildcache
    - --progress=plain
  inlineCache: true
```

### 3. Multi-Stage Builds

The frontend uses multi-stage builds for production optimization:
- **Stage 1:** Build the React application
- **Stage 2:** Serve with Nginx

## Cache Strategy

### Development vs Production Caches

- **Production builds:** Use `buildcache` tags
- **Development builds:** Use `devcache` tags with fallback to production cache

### Cache Hierarchy

1. Component-specific dev cache (e.g., `fastapi-backend:devcache`)
2. Component production cache (e.g., `fastapi-backend:buildcache`)
3. Fresh build if no cache available

## Build Performance Tips

### 1. Layer Optimization

Dependencies are installed before copying source code to maximize cache reuse:

```dockerfile
# Install dependencies first (cached)
COPY package*.json /app/
RUN npm ci

# Copy source code last (cache invalidated on code changes)
COPY ./ /app/
```

### 2. Registry Cache Management

Clean up old cache entries periodically:

```bash
# List cache references
docker images | grep buildcache

# Remove old cache tags
docker rmi react-frontend:buildcache-old
```

### 3. Local Development

For local development, BuildKit automatically reuses layers between builds, significantly reducing build times when only code changes.

## Troubleshooting

### BuildKit Not Available

If you get "buildkit not supported" errors:

```bash
# Check Docker version (requires 18.09+)
docker version

# Enable experimental features in Docker daemon
# Add to /etc/docker/daemon.json:
{
  "experimental": true,
  "features": {
    "buildkit": true
  }
}
```

### Cache Issues

If builds are slow despite caching:

```bash
# Check if cache is being used
devspace build --verbose

# Force rebuild without cache
devspace build --force-rebuild

# Clear local BuildKit cache
docker builder prune
```

### Registry Cache Permissions

Ensure your registry supports cache manifests and you have push permissions for cache references.

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v2

- name: Login to Registry
  uses: docker/login-action@v2
  with:
    registry: your-registry.com
    username: ${{ secrets.REGISTRY_USERNAME }}
    password: ${{ secrets.REGISTRY_PASSWORD }}

- name: Deploy with DevSpace
  run: |
    export DOCKER_BUILDKIT=1
    devspace deploy --profile production
```

The BuildKit setup provides:
- **Faster builds** through intelligent caching
- **Reduced resource usage** with efficient layer management
- **Better CI/CD performance** with registry-based cache sharing
- **Development-production parity** with shared cache layers