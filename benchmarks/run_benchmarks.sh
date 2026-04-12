#!/bin/bash
# run_benchmarks.sh — Run all CIRA benchmarks and produce eval-commands.tex
#
# Usage:
#   ./run_benchmarks.sh [--hardware]    # default: --simulate
#
# Output:
#   results/benchmark_results.json
#   ../eval-commands.tex (updated with real data)

set -euo pipefail
cd "$(dirname "$0")"

MODE="--simulate"
if [[ "${1:-}" == "--hardware" ]]; then
    MODE="--hardware"
    echo "Running in HARDWARE mode (requires sudo for /dev/mem access)"
fi

mkdir -p results

echo "================================================================"
echo "CIRA Benchmark Suite"
echo "Mode: ${MODE}"
echo "Date: $(date -Iseconds)"
echo "================================================================"

echo ""
echo "--- MCF ---"
./mcf_cira ${MODE} --iterations 1000 --arcs 100000 --depth 16 \
    | tee results/mcf_results.txt

echo ""
echo "================================================================"
echo "Benchmark suite complete. Results in benchmarks/results/"
echo "================================================================"
