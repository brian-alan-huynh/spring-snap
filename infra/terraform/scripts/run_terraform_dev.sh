#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

BACKEND_ENV_PATH="/backend/.env"
TF_DEV_ENV_PATH="/infra/terraform/environments/dev"

echo "Provisioning Terraform resources"

terraform -chdir="$TF_DEV_ENV_PATH" init
terraform -chdir="$TF_DEV_ENV_PATH" plan
terraform -chdir="$TF_DEV_ENV_PATH" apply -auto-approve

echo "Terraform resources successfully created"

tf_outputs="$(terraform -chdir="$TF_DEV_ENV_PATH" output -json)"

get_tf_output() {
    local key="$1"

    value="$(echo "$tf_outputs" | jq -r ".${key}.value")"

    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "Error: Missing Terraform output for ${key}" >&2
        exit 1
    fi

    echo "$value"
}

declare -A outputs=(
    [AWS_REGION]="aws_region"
    [AWS_RDS_SECRET_ARN]="aws_rds_secret_arn"
    [AWS_S3_BUCKET_NAME]="aws_s3_bucket_name"
    [KAFKA_SECRET_ARN]="kafka_secret_arn"
    [KAFKA_BOOTSTRAP_SERVERS]="kafka_bootstrap_servers"
    [REDIS_SECRET_ARN]="redis_secret_arn"
    [MONGODB_SECRET_ARN]="mongodb_secret_arn"
    [MONGODB_DB_NAME]="mongodb_db_name"
)

echo "Exporting Terraform outputs to .env file"

for key in "${!outputs[@]}"; do
    output="$(get_tf_output "${outputs[$key]}")"
    sed -i.bak "s|^${key}=.*|${key}=${output}|" "$BACKEND_ENV_PATH"
done

echo "Terraform outputs successfully exported to .env file"

echo ".env file with brand new environment variables:"
cat "$BACKEND_ENV_PATH"
