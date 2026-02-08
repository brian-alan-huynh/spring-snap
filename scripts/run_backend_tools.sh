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

BACKEND_PATH="${PROJECT_ROOT_DIR}/backend"

cd "$BACKEND_PATH"

echo -e "\nStarting Pylint tests for static code analysis and code quality\n"

mapfile -t py_files < <(find "${BACKEND_PATH}" -type f -name "*.py" \
    ! -path "*/venv/*" \
    ! -path "*/docker/*" \
    ! -path "*/tests/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/__init__.py"
)

if [ "${#py_files[@]}" -gt 0 ]; then
    pylint "${py_files[@]}"
else
    echo -e "\nNo .py files found for a Pylint analysis\n"
fi

echo -e "\nPylint analysis completed\n"

echo -e "\nStarting Pyre type checking\n"

if [[ ! -f "${BACKEND_PATH}/.pyre_configuration" ]]; then
    echo -e "\nInitializing Pyre\n"
    pyre init
fi

echo -e "\nRunning Pyre type checking\n"
pyre --noninteractive check --output json > "${BACKEND_PATH}/reports/pyreTypeCheckingReport.json"

echo -e "\nPyre type checking completed\n"

echo -e "\nStarting Pytest tests for unit and integration testing\n"

pytest --strict-markers --cov="${BACKEND_PATH}" --cov-report=term --cov-report=json:"${BACKEND_PATH}/reports/codeCoverageReport.json"

echo -e "\nPytest testing completed\n"

echo -e "\nTesting and analysis completed\n"
echo -e "\nPylint code analysis passed\n"
echo -e "\nPytests code testing passed\n"
echo -e "\nPyre type checking passed\n"
echo -e "\nCode coverage testing reports generated as an JSON file, called codeCoverageReport.json\n"
