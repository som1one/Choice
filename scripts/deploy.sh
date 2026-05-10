#!/bin/bash
# =============================================================================
# CHOICE APP - Deployment Script
# Run this to deploy or update the application
# =============================================================================

set -e

echo "================================================================"
echo "  CHOICE APP - Deployment"
echo "================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/choice-app"
BACKUP_DIR="/opt/backups"
COMPOSE_FILE="docker-compose.yml"

compose() {
    if docker compose version > /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" "$@"
    else
        docker-compose -f "$COMPOSE_FILE" "$@"
    fi
}

# Functions
log_info() {
    echo -e "${GREEN}➤${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Change to app directory
cd "$APP_DIR" || {
    log_error "Failed to change to $APP_DIR"
    exit 1
}

# Check if .env exists
if [ ! -f .env ]; then
    log_error ".env file not found!"
    log_info "Please copy .env.example to .env and configure it:"
    log_info "  cp .env.example .env"
    log_info "  nano .env"
    exit 1
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

log_info "Starting deployment..."

# Pull latest changes if it's a git repo
if [ -d ".git" ]; then
    log_info "Pulling latest changes from git..."
    git pull origin main || git pull origin master || log_warn "Git pull failed, using local files"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database if it exists
if docker ps | grep -q choice_postgres; then
    log_info "Creating database backup..."
    BACKUP_FILE="$BACKUP_DIR/choice_db_$(date +%Y%m%d_%H%M%S).sql"
    docker exec choice_postgres pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_FILE" || {
        log_warn "Database backup failed, continuing anyway..."
    }
    log_info "Backup saved to: $BACKUP_FILE"
fi

# Build Flutter web if source exists
if [ -d "client_app_flutter" ]; then
    log_info "Building Flutter web..."
    
    # Check if Flutter is installed locally
    if command -v flutter &> /dev/null; then
        cd client_app_flutter
        flutter build web \
            --dart-define=USE_REMOTE_API=true \
            --dart-define=API_HOST="${API_HOST:-localhost}" \
            --dart-define=API_SCHEME="${API_SCHEME:-http}" \
            --release
        cd ..
        log_info "Flutter web built successfully"
    else
        log_warn "Flutter not found locally. Using Docker build..."
        compose --profile build run --rm flutter_build
    fi
fi

# Stop existing containers
log_info "Stopping existing containers..."
compose down --remove-orphans

# Clean up old images and volumes (optional, keeps last 3 days)
log_info "Cleaning up old Docker data..."
docker system prune -f --filter "until=72h" || true

# Build and start services
log_info "Building and starting services..."
compose build --parallel
compose up -d

# Wait for services to be healthy
log_info "Waiting for services to start..."
sleep 10

# Check service health
log_info "Checking service health..."
SERVICES=(
    "choice_auth:8001"
    "choice_client:8002"
    "choice_company:8003"
    "choice_category:8004"
    "choice_ordering:8005"
    "choice_chat:8006"
    "choice_review:8007"
    "choice_file:8008"
)

ALL_HEALTHY=true
for service_port in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    if docker ps | grep -q "$service"; then
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1 || \
           curl -s "http://localhost:$port/docs" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $service (port $port)"
        else
            echo -e "  ${YELLOW}⚠${NC} $service (port $port) - no health endpoint"
        fi
    else
        echo -e "  ${RED}✗${NC} $service - not running"
        ALL_HEALTHY=false
    fi
done

echo ""
if [ "$ALL_HEALTHY" = true ]; then
    log_info "All services are running!"
else
    log_warn "Some services may need attention. Check logs with: docker compose logs"
fi

# Show running containers
echo ""
echo "================================================================"
echo "  Running Containers"
echo "================================================================"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep choice || true

echo ""
echo "================================================================"
echo "  Deployment Complete!"
echo "================================================================"
echo ""
echo "Access your application:"
echo "  • Web App:        http://${API_HOST:-localhost} (optional nginx static host)"
echo "  • Auth Docs:      http://${API_HOST:-localhost}:8001/docs"
echo "  • Client Docs:    http://${API_HOST:-localhost}:8002/docs"
echo ""
echo "Useful commands:"
echo "  • View logs:      docker compose logs -f"
echo "  • Stop all:       docker compose down"
echo "  • Restart:        docker compose restart"
echo "  • Update:         ./scripts/deploy.sh"
echo ""
