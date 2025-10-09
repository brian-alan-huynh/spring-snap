#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
TAG="latest"

echo "Authenticating to AWS ECR"

aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "AWS ECR authenticated"

build_push_docker_image() {
    local repo_url="$1"
    local file_path="$2"
    local context_path="$3"

    local image_name
    image_name="$(basename "$repo_url")"

    echo "Building Docker image called ${image_name}, located in ${file_path}, with context at ${context_path}"

    docker build -t "$image_name" -f "$file_path" "$context_path"

    echo "Tagging Docker image called ${image_name}, with ECR repo URL of ${repo_url}, and tag of ${TAG}"

    docker tag "$image_name" "${repo_url}:${TAG}"

    echo "Pushing Docker image called ${image_name}, with ECR repo URL of ${repo_url}, and tag of ${TAG}"
    
    docker push "${repo_url}:${TAG}"
}

repo_url_outputs="$(terraform -chdir=/infra/terraform/environments/prod output -json)"

backend_repo_url="$(echo "$repo_url_outputs" | jq -r '.ecr_repository_url_backend.value')"
frontend_repo_url="$(echo "$repo_url_outputs" | jq -r '.ecr_repository_url_frontend.value')"

echo "Building Docker image for backend and pushing to AWS ECR"

build_push_docker_image "$backend_repo_url" "/backend/docker/Dockerfile" "/backend"

echo "Backend Docker image successfully built and pushed to AWS ECR"

echo "Building Docker image for frontend and pushing to AWS ECR"

build_push_docker_image "$frontend_repo_url" "/frontend/docker/Dockerfile" "/frontend"

echo "Frontend Docker image successfully built and pushed to AWS ECR"
