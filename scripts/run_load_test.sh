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

K6_PATH="${PROJECT_ROOT_DIR}/k6"

echo -e "\nChecking for required environment variable's existence\n"

BASE_URL="$1"
WEB_URL="$2"
K6_CLOUD_TOKEN="$3"

if [ -z "${BASE_URL}" ]; then
  echo -e "\nError: BASE_URL environment variable must be set\n"
  exit 1
fi

if [ -z "${WEB_URL}" ]; then
  echo -e "\nError: WEB_URL environment variable must be set\n"
  exit 1
fi

if [ -z "${K6_CLOUD_TOKEN}" ]; then
  echo -e "\nError: K6_CLOUD_TOKEN environment variable must be set\n"
  exit 1
fi

echo -e "\nAll required environment variables are present\n"

K6_TEST_FILE="${K6_PATH}/load-test.js"
SUMMARY_OUTPUT_FILE="${K6_PATH}/reports/load-test-summary.json"

echo -e "\nStarting K6 container\n"

docker run \
  --rm \
  -i \
  -v "${PROJECT_ROOT_DIR}:/src" \
  -w /src \
  -e BASE_URL="${BASE_URL}" \
  -e WEB_URL="${WEB_URL}" \
  -e K6_CLOUD_TOKEN="${K6_CLOUD_TOKEN}" \
  grafana/k6:latest \
  k6 cloud \
    --scenario average_load_test \
    --summary-export="${SUMMARY_OUTPUT_FILE}" \
    "${K6_TEST_FILE}"

echo -e "\nK6 load testing execution finished\n"

if [ -f "${SUMMARY_OUTPUT_FILE}" ]; then
  echo -e "\n${SUMMARY_OUTPUT_FILE} load test summary report has been generated\n"
else
  echo -e "\nWarning, ${SUMMARY_OUTPUT_FILE} load test summary report was not created\n"
fi

echo -e "\nK6 load testing successfully completed\n"
