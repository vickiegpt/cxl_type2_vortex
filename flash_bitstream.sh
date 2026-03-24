#!/bin/bash

# Flash newly compiled bitstream to FPGA
# Usage: ./flash_bitstream.sh

set -e

BITSTREAM_DIR="hardware_test_design/output_files"
BITSTREAM_FILE="cxltyp2_ed.sof"
QUARTUS_PATH="/opt/altera_pro/25.1/quartus/bin"

echo "=== Flashing GPU CSR Remapping Bitstream ==="
echo ""

# Check if bitstream exists
if [ ! -f "$BITSTREAM_DIR/$BITSTREAM_FILE" ]; then
    echo "ERROR: Bitstream not found at $BITSTREAM_DIR/$BITSTREAM_FILE"
    echo "Compilation may not be complete. Check compile_output_*.log"
    exit 1
fi

echo "Bitstream file: $BITSTREAM_DIR/$BITSTREAM_FILE"
ls -lh "$BITSTREAM_DIR/$BITSTREAM_FILE"
echo ""

# Flash using Quartus Programmer
echo "Flashing to FPGA via JTAG..."
"$QUARTUS_PATH/quartus_pgm" -m jtag -o "P;$BITSTREAM_DIR/$BITSTREAM_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Bitstream flashed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. System will reboot automatically (if configured)"
    echo "2. Or manually reboot: sudo reboot"
    echo "3. Run tests to verify CSR access:"
    echo "   sudo ./tests/simple_csr_test"
else
    echo ""
    echo "✗ Flashing failed. Check JTAG connection."
    exit 1
fi
