#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

CURRENT_DIR="$SCRIPT_DIR"
MARKER="README.md"

while [ ! -f "${CURRENT_DIR}/${MARKER}" ] && [ "$CURRENT_DIR" != "/" ]; do
    CURRENT_DIR="$(dirname "$CURRENT_DIR")"
done

if [ ! -f "${CURRENT_DIR}/${MARKER}" ]; then
    echo "Error: Unable to find project root dir"
    exit 1
fi

PROJECT_ROOT_DIR="${CURRENT_DIR}"

BACKEND_ENV_PATH="${PROJECT_ROOT_DIR}/backend/.env"
TF_PROD_ENV_PATH="${PROJECT_ROOT_DIR}/infra/terraform/environments/prod"

declare -A env_vars=(
    [GOOGLE_CLIENT_ID]="google_client_id"
    [GOOGLE_CLIENT_SECRET]="google_client_secret"
    [FACEBOOK_CLIENT_ID]="facebook_client_id"
    [FACEBOOK_CLIENT_SECRET]="facebook_client_secret"
    [APPLE_CLIENT_ID]="apple_client_id"
    [APPLE_CLIENT_SECRET]="apple_client_secret"
    [MONGODB_DB_COLLECTION_NAME]="mongodb_db_collection_name"
    [ROBOFLOW_MODEL_PATH]="roboflow_model_path"
    [ROBOFLOW_API_KEY]="roboflow_api_key"
    [SMTP_SERVER]="smtp_server"
    [SMTP_SERVER_PORT]="smtp_server_port"
    [SMTP_EMAIL_APP_PASS]="smtp_email_app_pass"
    [GRAFANA_LOKI_URL]="grafana_loki_url"
    [GRAFANA_LOKI_USERNAME]="grafana_loki_username"
    [GRAFANA_LOKI_PASSWORD]="grafana_loki_password"
    [APP_CSRF_SECRET_KEY]="app_csrf_secret_key"
)

echo "Loading .env variables"

set -o allexport
source "$BACKEND_ENV_PATH"
set +o allexport

echo "Finished loading .env variables"

cd "$TF_PROD_ENV_PATH"

echo "Exporting .env variables to Terraform"

for key in "${!env_vars[@]}"; do
    if [ -z "${!key:-}" ]; then
        echo "Error: Missing .env variable called ${key}" >&2
        exit 1
    fi

    export TF_VAR_${env_vars[$key]}="${!key}"
done

echo ".env variables successfully exported to Terraform"

echo "Provisioning Terraform resources"

terraform init
terraform plan
terraform apply -auto-approve

echo "Terraform resources successfully created"
