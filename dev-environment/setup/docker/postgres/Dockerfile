FROM postgres:15-alpine

# Install additional tools for Pentaho setup
RUN apk add --no-cache \
    curl \
    postgresql-contrib \
    postgresql-client

# Set default environment (will be overridden by docker-compose)
ENV POSTGRES_DB=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB