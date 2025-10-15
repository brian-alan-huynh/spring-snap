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

FRONTEND_PATH="${PROJECT_ROOT_DIR}/frontend"

cd "$FRONTEND_PATH"

echo -e "\nStarting ESLint test for code analysis and quality\n"

pnpm lint

echo -e "\nESLint analysis completed\n"

echo -e "\nStarting Jest tests for unit and integration testing\n"

pnpm test

echo -e "\nJest testing completed with a code coverage report generated\n"
