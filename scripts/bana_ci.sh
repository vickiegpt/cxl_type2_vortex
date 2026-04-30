#!/usr/bin/env bash
set -euo pipefail

target="${1:-quartus}"

export LM_LICENSE_FILE="${LM_LICENSE_FILE:-/opt/altera_pro/25.1/lic_qsim_24_any.dat}"
export ALTERA_ROOT="${ALTERA_ROOT:-/opt/alterapro_25.1}"
export QUARTUS_ROOTDIR="${QUARTUS_ROOTDIR:-${ALTERA_ROOT}/quartus}"

if [[ -d "${QUARTUS_ROOTDIR}/bin" ]]; then
    export PATH="${QUARTUS_ROOTDIR}/bin:${PATH}"
fi

echo "Host: $(hostname)"
echo "Repository: $(pwd)"
echo "Target: ${target}"
echo "LM_LICENSE_FILE=${LM_LICENSE_FILE}"
echo "ALTERA_ROOT=${ALTERA_ROOT}"
echo "QUARTUS_ROOTDIR=${QUARTUS_ROOTDIR}"

if command -v quartus_sh >/dev/null 2>&1; then
    quartus_sh --version || true
else
    echo "quartus_sh not found in PATH"
fi

case "${target}" in
    cpp)
        bash tests/run_tests.sh cpp
        ;;
    gemm)
        bash tests/run_tests.sh gemm
        ;;
    rtl)
        bash tests/run_tests.sh rtl
        ;;
    tests | all)
        bash tests/run_tests.sh all
        ;;
    quartus | compile)
        if ! command -v quartus_sh >/dev/null 2>&1; then
            echo "ERROR: quartus_sh not found. Expected it under ${QUARTUS_ROOTDIR}/bin."
            exit 127
        fi
        cd hardware_test_design
        quartus_sh -t compile.tcl
        ;;
    *)
        echo "Unknown target: ${target}"
        echo "Valid targets: quartus, tests, cpp, gemm, rtl"
        exit 2
        ;;
esac
