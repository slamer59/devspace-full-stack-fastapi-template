#!/bin/bash

# Script to validate BuildKit setup for DevSpace
set -e

echo "🔍 Validating BuildKit setup..."
echo

# Check if BuildKit is enabled
if ! docker version --format '{{.Server.Version}}' | grep -E "^(1[89]|[2-9][0-9]|1\.1[89]|1\.[2-9][0-9])" > /dev/null 2>&1; then
    echo "❌ Docker version is too old for BuildKit. Please upgrade to Docker 18.09 or later."
    exit 1
else
    echo "✅ Docker version is compatible with BuildKit"
fi

# Check if BuildKit is enabled
if [ "${DOCKER_BUILDKIT:-}" != "1" ]; then
    echo "⚠️  DOCKER_BUILDKIT is not set to 1. Setting it now..."
    export DOCKER_BUILDKIT=1
    echo "✅ DOCKER_BUILDKIT enabled"
else
    echo "✅ DOCKER_BUILDKIT is already enabled"
fi

# Check if buildx is available (optional but recommended)
if docker buildx version > /dev/null 2>&1; then
    echo "✅ Docker Buildx is available"
    
    # Show current builder
    echo "📋 Current builder:"
    docker buildx inspect --bootstrap 2>/dev/null | grep -E "Name:|Driver:|Status:" || true
else
    echo "⚠️  Docker Buildx is not available (optional)"
fi

echo

# Validate DevSpace configuration
echo "🔍 Validating DevSpace BuildKit configuration..."

if [ ! -f "devspace.yaml" ]; then
    echo "❌ devspace.yaml not found in current directory"
    exit 1
fi

# Check if BuildKit is configured in DevSpace
if grep -q "buildKit:" devspace.yaml; then
    echo "✅ BuildKit configuration found in devspace.yaml"
    
    # Check for cache configuration
    if grep -q "cache-to=type=registry" devspace.yaml; then
        echo "✅ Registry caching configured"
    elif grep -q "cache-to=type=local" devspace.yaml; then
        echo "✅ Local caching configured"
    else
        echo "⚠️  No caching configuration found"
    fi
    
    if grep -q "inlineCache: true" devspace.yaml; then
        echo "✅ Inline cache enabled"
    fi
else
    echo "❌ BuildKit configuration not found in devspace.yaml"
    exit 1
fi

echo

# Test build with BuildKit
echo "🧪 Testing BuildKit build..."

# Check if we can analyze the backend Dockerfile
if [ -f "backend/Dockerfile" ]; then
    echo "Testing backend Dockerfile with BuildKit..."
    if grep -q "mount=type=cache" backend/Dockerfile; then
        echo "✅ Backend Dockerfile uses BuildKit cache mounts"
    else
        echo "⚠️  Backend Dockerfile could benefit from BuildKit cache mounts"
    fi
fi

# Check if we can analyze the frontend Dockerfile
if [ -f "frontend/Dockerfile" ]; then
    echo "Testing frontend Dockerfile with BuildKit..."
    if grep -q "mount=type=cache" frontend/Dockerfile; then
        echo "✅ Frontend Dockerfile uses BuildKit cache mounts"
    else
        echo "⚠️  Frontend Dockerfile could benefit from BuildKit cache mounts"
    fi
fi

echo

# Check DevSpace version
if command -v devspace > /dev/null 2>&1; then
    DEVSPACE_VERSION=$(devspace version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
    echo "✅ DevSpace CLI version: $DEVSPACE_VERSION"
else
    echo "❌ DevSpace CLI not found. Please install DevSpace CLI."
    exit 1
fi

echo
echo "🎉 BuildKit setup validation completed!"
echo
echo "💡 Tips:"
echo "   • Use 'devspace build --verbose' to see BuildKit in action"
echo "   • Check build logs for cache hits: 'CACHED' messages indicate cache usage"  
echo "   • Use 'docker system df' to see BuildKit cache usage"
echo "   • Clean BuildKit cache with 'docker builder prune'"
echo
echo "🚀 Ready to use DevSpace with BuildKit!"
echo "   • Backend dev:  devspace dev --config devspace-backend.yaml"
echo "   • Frontend dev: devspace dev --config devspace-frontend.yaml"
echo "   • Full stack:   devspace deploy"