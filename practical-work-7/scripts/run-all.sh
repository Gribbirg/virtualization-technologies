#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "Running all tests for Practical Work 7"
echo "========================================="
echo ""

echo "Step 1: Setup environment"
bash "$SCRIPT_DIR/setup.sh"
echo ""

echo "Step 2: Test memory requests and limits"
bash "$SCRIPT_DIR/test-memory.sh"
echo ""

echo "Step 3: Test CPU requests and limits"
bash "$SCRIPT_DIR/test-cpu.sh"
echo ""

echo "Step 4: Cleanup"
bash "$SCRIPT_DIR/cleanup.sh"
echo ""

echo "========================================="
echo "All tests completed successfully!"
echo "========================================="
