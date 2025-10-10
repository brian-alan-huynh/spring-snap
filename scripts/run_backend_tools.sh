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

BACKEND_PATH="${PROJECT_ROOT_DIR}/backend"

cd "$BACKEND_PATH"

echo "Starting Pylint tests for static code analysis and code quality"

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
    echo "No .py files found for a Pylint analysis"
fi

echo "Pylint analysis completed"

echo "Starting Pytest tests for unit and integration testing"

pytest --strict-markers --cov="${BACKEND_PATH}" --cov-report=term --cov-report=xml:"${BACKEND_PATH}/codeCoverageReport.xml"

echo "Pytest testing completed"

echo "Testing and analysis completed"
echo "Pylint code analysis passed"
echo "Pytests code testing passed"
echo "Code coverage testing reports generated as an XML file, called codeCoverageReport.xml"
