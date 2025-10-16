#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

echo -e "\nStarting Curby Storage entrypoint script\n"

echo -e "\nEnvironment: ${NODE_ENV:-development}"
echo "Node version: $(node --version)"
echo "PNPM version: $(pnpm --version)"
echo -e "Working directory: $(pwd)\n"

wait_for_backend() {
    local backend_url="${VITE_API_BASE_URL:-http://localhost:8000}"
    local max_retries=30
    local retry=0

    echo -e "\nWaiting for backend at ${backend_url}\n"

    while [[ "$retry" -lt "$max_retries" ]]; do
        if wget --spider -q "${backend_url}/health" 2>/dev/null; then
            echo -e "\nBackend is ready\n"
            return 0
        fi

        retry=$((retry + 1))

        echo -e "\n Starting attempt ${retry}/${max_retries} (backend is not ready as of now)\n"

        sleep 2
    done

    echo -e "\nBackend is not available; continuing anyway\n"

    return 1
}

if [[ "$NODE_ENV" == "development" ]]; then
    echo -e "\nDevelopment mode detected\n"

    if [[ ! -d "node_module" ]] || [[ -z "$(ls -A node_modules 2>/dev/null)" ]]; then
        echo -e "\nThe directory node_modules is either not found or empty; installing dependencies\n"
        pnpm install
    else
        echo -e "\nThe directory node_modules exists and is not empty; skipping installation\n"
    fi

    if [[ -n "$VITE_API_BASE_URL" ]]; then
        echo -e "\nStarting process for waiting for backend\n"
        wait_for_backend || true
    fi
fi

echo -e "\nCurby Storage entrypoint script finished\n"

echo -e "\nStarting Curby Storage at ${NODE_ENV:-development} environment\n"

exec "$@"
