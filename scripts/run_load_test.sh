#!/bin/bash

set -e

echo " K6 Test Runner Initialized..."

: "${K6_TEST_SCENARIO:=average_load_test}"
: "${K6_TEST_FILE:=load-test.js}"
K6_DOCKER_IMAGE="grafana/k6:latest"
SUMMARY_OUTPUT_FILE="load-test-summary.json"


if [ -z "${BASE_URL}" ] || [ -z "${WEB_URL}" ]; then
  echo " Error: BASE_URL and WEB_URL environment variables must be set."
  exit 1
fi

if [ ! -f "${K6_TEST_FILE}" ]; then
  echo " Error: K6 test file not found at '${K6_TEST_FILE}'"
  exit 1
fi

echo " Test Configuration:"
echo "  -> API Target URL (BASE_URL): ${BASE_URL}"
echo "  -> Web App Target URL (WEB_URL): ${WEB_URL}"
echo "  -> Test Scenario: ${K6_TEST_SCENARIO}"
echo "  -> Test File: ${K6_TEST_FILE}"
echo "-----------------------------------------------------"

K6_COMMAND="k6 run"

if [ -n "${K6_CLOUD_TOKEN}" ]; then
  echo " K6_CLOUD_TOKEN detected. Streaming results to Grafana Cloud."
  K6_COMMAND="k6 cloud"
else
  echo " No K6_CLOUD_TOKEN detected. Running test locally and generating summary report."
fi

echo " Starting K6 container..."

docker run --rm -i \
  -v "${PWD}:/src" \
  -w /src \
  -e BASE_URL="${BASE_URL}" \
  -e WEB_URL="${WEB_URL}" \
  -e K6_CLOUD_TOKEN="${K6_CLOUD_TOKEN}" \
  "${K6_DOCKER_IMAGE}" \
  ${K6_COMMAND} \
  --scenario "${K6_TEST_SCENARIO}" \
  --summary-export="${SUMMARY_OUTPUT_FILE}" \
  "${K6_TEST_FILE}"

echo "-----------------------------------------------------"
echo " K6 test execution finished."

if [ -f "${SUMMARY_OUTPUT_FILE}" ]; then
  echo " Performance test summary report generated at '${SUMMARY_OUTPUT_FILE}'."
  echo " This file can be stored as a build artifact for trend analysis."
else
  echo " Warning: Summary report file was not created."
fi

echo "K6 Test Run Completed Successfully."
