#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

echo "Starting Pylint tests for static code analysis and code quality"

mapfile -t py_files < <(find backend -type f -name "*.py" \
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

pytest --strict-markers --cov=backend --cov-report=term --cov-report=xml:codeCoverageReport.xml

echo "Pytest testing completed"

echo "Testing and analysis completed"
echo "Pylint code analysis passed"
echo "Pytests code testing passed"
echo "Code coverage testing reports generated as an XML file, called codeCoverageReport.xml"
