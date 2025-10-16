#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

echo -e "\nStarting Curby Storage entrypoint script\n"

echo -e "\nEnvironment: ${ENVIRONMENT:-not set}"
echo "Python version: $(python --version)"
echo -e "Working directory: $(pwd)\n"

wait_for_service() {
    local host="$1"
    local port="$2"
    local service="$3"

    local max_retries=30
    local retry=0

    echo -e "\nWaiting for ${service} at ${host}:${port}\n"

    while [ "$retry" -lt "$max_retries" ]; do
        if nc -z "$host" "$port" > /dev/null 2>&1; then
            echo -e "\n${service} is ready\n"
            return 0
        fi

        retry=$((retry + 1))
        
        echo -e "\nAttempt ${retry}/${max_retries} (${service} not ready yet)\n"

        sleep 2
    done

    echo -e "\n${service} failed to become ready after ${max_retries} attempts\n"

    return 1
}

check_service_health() {
    local url="$1"
    local service="$2"

    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "\n${service} health check passed\n"
        return 0
    else
        echo -e "\n${service} health check failed\n"
        return 1
    fi
}

if [[ "$ENVIRONMENT" == "dev" ]]; then
    echo -e "\nDev environment (waiting for services to become ready)\n"

    if [[ -n "$RDS_DB_HOST" ]] && [[ "$RDS_DB_HOST" != "localhost" ]]; then
        wait_for_service "$RDS_DB_HOST" "${RDS_DB_PORT:-5432}" "PostgreSQL" || true
    else
        wait_for_service "postgres" "5432" "PostgreSQL" || true
    fi

    if [[ -n "$REDIS_HOST" ]] && [[ "$REDIS_HOST" != "localhost" ]]; then
        wait_for_service "$REDIS_HOST" "${REDIS_PORT:-6379}" "Redis" || true
    else
        wait_for_service "redis" "6379" "Redis" || true
    fi

    if [[ -n "$MONGODB_HOST" ]] && [[ $"MONGODB_HOST" != "localhost" ]]; then
        wait_for_service "$MONGODB_HOST" "${MONGODB_PORT:-27017}" "MongoDB" || true
    else
        wait_for_service "mongodb" "27017" "MongoDB" || true
    fi

    if [[ -n "$AWS_ENDPOINT_URL" ]]; then
        wait_for_service "localstack" "4566" "LocalStack" || true
        check_service_health "${AWS_ENDPOINT_URL}/_localstack/health" "LocalStack" || true
    fi

    echo -e "\nServices are ready\n"
fi

if [[ "$ENVIRONMENT" == "dev" ]]; then
    echo -e "\nChecking for database initialization\n"
    python -c "from infra.db import RDS; RDS()" || echo -e "\nDatabase initialization failed and skipped\n"
fi

if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo -e "\nValidating environment variables\n"

    required_vars=(
        "ENVIRONMENT"
        "AWS_REGION"
        "AWS_RDS_SECRET_ARN"
        "REDIS_SECRET_ARN"
        "MONGODB_SECRET_ARN"
        "KAFKA_SECRET_ARN"
        "AWS_S3_BUCKET_NAME"
        "APP_CSRF_SECRET_KEY"
    )

    missing_vars=()

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done

    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        echo -e "\nMissing required environment variables:"
        echo -e "${missing_vars[@]}\n"

        exit 1
    fi

    echo -e "\nEnvironment variables are set and valid\n"
fi

echo -e "\nCurby Storage entrypoint script finished\n"

echo -e "\nStarting Curby Storage at ${ENVIRONMENT:-dev} environment\n"

exec "$@"
