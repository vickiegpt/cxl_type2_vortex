#!/bin/bash
# run_benchmarks.sh — Run all CIRA benchmarks (real hardware only)
#
# Usage:
#   sudo ./run_benchmarks.sh [--iterations N] [--arcs N] [--depth N]
#
# Requires: root for /dev/mem BAR0 access
#
# Output:
#   results/mcf_results.txt

set -euo pipefail
cd "$(dirname "$0")"

ITERATIONS="${ITERATIONS:-1000}"
ARCS="${ARCS:-100000}"
DEPTH="${DEPTH:-16}"

# Parse overrides
while [[ $# -gt 0 ]]; do
    case "$1" in
        --iterations) ITERATIONS="$2"; shift 2 ;;
        --arcs)       ARCS="$2";       shift 2 ;;
        --depth)      DEPTH="$2";      shift 2 ;;
        *)            echo "Unknown arg: $1"; exit 1 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must run as root (need /dev/mem access for BAR0)"
    exit 1
fi

mkdir -p results

echo "================================================================"
echo "CIRA Benchmark Suite (Hardware)"
echo "Date: $(date -Iseconds)"
echo "Host: $(hostname)"
echo "Kernel: $(uname -r)"
echo "================================================================"

echo ""
echo "--- MCF ---"
./mcf_cira --iterations "${ITERATIONS}" --arcs "${ARCS}" --depth "${DEPTH}" \
    | tee results/mcf_results.txt

echo ""
echo "================================================================"
echo "Benchmark suite complete. Results in benchmarks/results/"
echo "================================================================"
