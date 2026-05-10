# Multi-service Dockerfile for Choice Backend
# Usage: docker build --build-arg SERVICE_NAME=authentication -t choice-auth .

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy shared backend code. Services import each other directly, so the
# complete services tree must be present in every image.
COPY common/ ./common/
COPY services/ ./services/
# etc/ is not tracked in git; file_service creates upload dirs at runtime via FILE_UPLOAD_PATH volume

# Build argument for service name
ARG SERVICE_NAME
ENV SERVICE_NAME=${SERVICE_NAME}

# Set Python path
ENV PYTHONPATH=/app

# Expose port (will be overridden by docker-compose)
EXPOSE 8000

# Run the selected service
CMD ["sh", "-c", "uvicorn services.${SERVICE_NAME}.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
