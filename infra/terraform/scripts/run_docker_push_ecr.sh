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
    echo -e "\nError: Unable to find project root dir\n"
    exit 1
fi

PROJECT_ROOT_DIR="${CURRENT_DIR}"

AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TAG="latest"

echo -e "\nAuthenticating to AWS ECR\n"

aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo -e "\nAWS ECR authenticated\n"

build_push_docker_image() {
    local repo_url="$1"
    local file_path="$2"
    local context_path="$3"

    local image_name
    image_name="$(basename "$repo_url")"

    echo -e "\nBuilding Docker image called ${image_name}, located in ${file_path}, with context at ${context_path}"

    docker build -t "$image_name" -f "$file_path" "$context_path"

    echo "Tagging Docker image called ${image_name}, with ECR repo URL of ${repo_url}, and tag of ${TAG}"

    docker tag "$image_name" "${repo_url}:${TAG}"

    echo -e "Pushing Docker image called ${image_name}, with ECR repo URL of ${repo_url}, and tag of ${TAG}\n"
    
    docker push "${repo_url}:${TAG}"
}

repo_url_outputs="$(terraform -chdir="${PROJECT_ROOT_DIR}/infra/terraform/environments/prod" output -json)"

backend_repo_url="$(echo "$repo_url_outputs" | jq -r '.ecr_repository_url_backend.value')"
frontend_repo_url="$(echo "$repo_url_outputs" | jq -r '.ecr_repository_url_frontend.value')"

echo -e "\nBuilding Docker image for backend and pushing to AWS ECR\n"

build_push_docker_image "$backend_repo_url" "${PROJECT_ROOT_DIR}/backend/docker/Dockerfile" "${PROJECT_ROOT_DIR}/backend"

echo -e "\nBackend Docker image successfully built and pushed to AWS ECR\n"

echo -e "\nBuilding Docker image for frontend and pushing to AWS ECR\n"

build_push_docker_image "$frontend_repo_url" "${PROJECT_ROOT_DIR}/frontend/docker/Dockerfile" "${PROJECT_ROOT_DIR}/frontend"

echo -e "\nFrontend Docker image successfully built and pushed to AWS ECR\n"
