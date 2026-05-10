#!/bin/bash
# =============================================================================
# CHOICE APP - Local Docker Test
# Тестирование Docker конфигурации перед деплоем на сервер
# =============================================================================

set -e

echo "================================================================"
echo "  CHOICE APP - Local Docker Test"
echo "================================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}➤${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_step() {
    echo -e "${BLUE}→${NC} $1"
}

compose() {
    if docker compose version > /dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

# Check prerequisites
log_step "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log_error "Docker not found. Please install Docker."
    exit 1
fi

if ! docker compose version > /dev/null 2>&1 && ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose not found. Please install Docker Compose."
    exit 1
fi

log_info "Docker version: $(docker --version)"
if docker compose version > /dev/null 2>&1; then
    log_info "Docker Compose version: $(docker compose version --short)"
else
    log_info "Docker Compose version: $(docker-compose --version)"
fi

# Create test .env if not exists
if [ ! -f .env ]; then
    log_warn ".env not found, creating from .env.example"
    cp .env.example .env
    # Modify for local testing
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=test_password/' .env
    sed -i 's/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=test-secret-key-for-local-development-only/' .env
    sed -i 's/API_HOST=.*/API_HOST=localhost/' .env
fi

# Clean up previous runs
log_step "Cleaning up previous runs..."
compose down -v 2>/dev/null || true
docker system prune -f 2>/dev/null || true

# Build images
log_step "Building Docker images..."
compose build --parallel

# Start services
log_step "Starting services..."
compose up -d postgres
sleep 5

log_step "Starting backend services..."
compose up -d

# Wait for services
log_step "Waiting for services to initialize (30s)..."
sleep 30

# Health checks
echo ""
echo "================================================================"
echo "  Health Checks"
echo "================================================================"

SERVICES=(
    "8001:auth"
    "8002:client"
    "8003:company"
    "8004:category"
    "8005:ordering"
    "8006:chat"
    "8007:review"
    "8008:file"
)

ALL_PASSED=true

for svc in "${SERVICES[@]}"; do
    IFS=':' read -r port name <<< "$svc"
    
    if curl -s "http://localhost:$port/docs" > /dev/null 2>&1; then
        log_info "✓ $name service (port $port) - OK"
    else
        log_error "✗ $name service (port $port) - FAILED"
        ALL_PASSED=false
    fi
done

echo ""

# Show running containers
echo "================================================================"
echo "  Running Containers"
echo "================================================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep choice || true

echo ""

# Summary
if [ "$ALL_PASSED" = true ]; then
    log_info "All tests passed! ✓"
    echo ""
    echo "Your Docker configuration is ready for production deployment!"
    echo ""
    echo "Next steps:"
    echo "  1. Push to GitHub: git push origin main"
    echo "  2. Follow DEPLOY.md for server setup"
    echo ""
    echo "Access local services:"
    echo "  • API Docs: http://localhost:8001/docs"
    echo "  • Client service: http://localhost:8002/docs"
    echo "  • Optional static web host: docker compose --profile web up -d nginx"
else
    log_error "Some services failed to start. Check logs:"
    echo "  docker compose logs -f"
    exit 1
fi

echo ""
echo "Press Ctrl+C to stop, or run 'docker compose down' to cleanup"
echo ""

# Keep running
wait
