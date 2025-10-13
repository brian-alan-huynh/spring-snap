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

K6_PATH="${PROJECT_ROOT_DIR}/k6"

echo "Checking for required environment variable's existence"

if [ -z "${BASE_URL}" ] || [ -z "${WEB_URL}" ]; then
  echo "Error: BASE_URL and WEB_URL environment variables must be set"
  exit 1
fi

if [ -z "${K6_CLOUD_TOKEN}" ]; then
  echo "Error: K6_CLOUD_TOKEN environment variable must be set"
  exit 1
fi

echo "All required environment variables are present"

K6_TEST_FILE="${K6_PATH}/load-test.js"
K6_TEST_SCENARIO="average_load_test"
SUMMARY_OUTPUT_FILE="${K6_PATH}/reports/load-test-summary.json"

echo "Starting K6 container"

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
    --scenario "${K6_TEST_SCENARIO}" \
    --summary-export="${SUMMARY_OUTPUT_FILE}" \
    "${K6_TEST_FILE}"

echo "K6 load testing execution finished"

if [ -f "${SUMMARY_OUTPUT_FILE}" ]; then
  echo "${SUMMARY_OUTPUT_FILE} load test summary report has been generated"
else
  echo "Warning, ${SUMMARY_OUTPUT_FILE} load test summary report was not created"
fi

echo "K6 load testing successfully completed"
