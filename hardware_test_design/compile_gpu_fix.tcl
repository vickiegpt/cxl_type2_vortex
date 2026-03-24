# Quartus compilation for GPU CSR bridge fix
set QPROJECT "cxltyp2_ed"
set REVISION "cxltyp2_ed"

# Open project
project_open $QPROJECT -revision $REVISION

# Perform analysis and synthesis
puts "Running synthesis (Analysis & Synthesis)..."
execute_module -tool syn

# Perform place and route
puts "Running place and route (Fitter)..."
execute_module -tool fit

# Perform timing analysis
puts "Running timing analysis (Timing Analyzer)..."
execute_module -tool sta

# Generate programming file
puts "Generating programming file (ASSEMBLER)..."
execute_module -tool asm

# Close project
project_close

puts "Compilation complete!"
