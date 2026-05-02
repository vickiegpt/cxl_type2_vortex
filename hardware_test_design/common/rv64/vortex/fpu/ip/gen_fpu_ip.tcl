# TCL script to generate Intel Floating Point IPs for Vortex GPU
# acl_fmadd - Fused Multiply-Add (FMA)
# acl_fdiv  - Floating Point Division
# acl_fsqrt - Floating Point Square Root

package require -exact qsys 24.0

# Create acl_fmadd - Single Precision FMA
proc create_fmadd {} {
    create_system acl_fmadd
    set_project_property DEVICE_FAMILY {Agilex 7}
    set_project_property DEVICE {AGIB027R29A1E2VR2}

    # Add clock and reset
    add_instance clk altera_clock_bridge
    set_instance_parameter_value clk {EXPLICIT_CLOCK_RATE} {0.0}
    set_instance_parameter_value clk {NUM_CLOCK_OUTPUTS} {1}

    # Add FP Functions IP for FMA
    add_instance fma altera_fp_functions
    set_instance_parameter_value fma {FUNCTION_FAMILY} {ARITH}
    set_instance_parameter_value fma {ARITH_FUNCTION} {FPMulAdd}
    set_instance_parameter_value fma {ARITH_FORMAT} {Single}
    set_instance_parameter_value fma {ARITH_LATENCY} {4}
    set_instance_parameter_value fma {ARITH_USE_MULT_ADDER} {1}
    set_instance_parameter_value fma {SELECTED_DEVICE_FAMILY} {Agilex 7}

    # Export interfaces
    add_interface clk clock sink
    set_interface_property clk EXPORT_OF clk.in_clk

    add_interface a conduit end
    set_interface_property a EXPORT_OF fma.a

    add_interface b conduit end
    set_interface_property b EXPORT_OF fma.b

    add_interface c conduit end
    set_interface_property c EXPORT_OF fma.c

    add_interface q conduit end
    set_interface_property q EXPORT_OF fma.q

    add_interface en conduit end
    set_interface_property en EXPORT_OF fma.en

    add_interface areset conduit end
    set_interface_property areset EXPORT_OF fma.areset

    add_connection clk.out_clk fma.clk

    save_system acl_fmadd.ip
}

# Create acl_fdiv - Single Precision Division
proc create_fdiv {} {
    create_system acl_fdiv
    set_project_property DEVICE_FAMILY {Agilex 7}
    set_project_property DEVICE {AGIB027R29A1E2VR2}

    add_instance clk altera_clock_bridge
    set_instance_parameter_value clk {EXPLICIT_CLOCK_RATE} {0.0}
    set_instance_parameter_value clk {NUM_CLOCK_OUTPUTS} {1}

    add_instance div altera_fp_functions
    set_instance_parameter_value div {FUNCTION_FAMILY} {ARITH}
    set_instance_parameter_value div {ARITH_FUNCTION} {DIVIDE}
    set_instance_parameter_value div {ARITH_FORMAT} {Single}
    set_instance_parameter_value div {ARITH_LATENCY} {15}
    set_instance_parameter_value div {SELECTED_DEVICE_FAMILY} {Agilex 7}

    add_interface clk clock sink
    set_interface_property clk EXPORT_OF clk.in_clk

    add_interface a conduit end
    set_interface_property a EXPORT_OF div.a

    add_interface b conduit end
    set_interface_property b EXPORT_OF div.b

    add_interface q conduit end
    set_interface_property q EXPORT_OF div.q

    add_interface en conduit end
    set_interface_property en EXPORT_OF div.en

    add_interface areset conduit end
    set_interface_property areset EXPORT_OF div.areset

    add_connection clk.out_clk div.clk

    save_system acl_fdiv.ip
}

# Create acl_fsqrt - Single Precision Square Root
proc create_fsqrt {} {
    create_system acl_fsqrt
    set_project_property DEVICE_FAMILY {Agilex 7}
    set_project_property DEVICE {AGIB027R29A1E2VR2}

    add_instance clk altera_clock_bridge
    set_instance_parameter_value clk {EXPLICIT_CLOCK_RATE} {0.0}
    set_instance_parameter_value clk {NUM_CLOCK_OUTPUTS} {1}

    add_instance sqrt altera_fp_functions
    set_instance_parameter_value sqrt {FUNCTION_FAMILY} {ARITH}
    set_instance_parameter_value sqrt {ARITH_FUNCTION} {SQRT}
    set_instance_parameter_value sqrt {ARITH_FORMAT} {Single}
    set_instance_parameter_value sqrt {ARITH_LATENCY} {10}
    set_instance_parameter_value sqrt {SELECTED_DEVICE_FAMILY} {Agilex 7}

    add_interface clk clock sink
    set_interface_property clk EXPORT_OF clk.in_clk

    add_interface a conduit end
    set_interface_property a EXPORT_OF sqrt.a

    add_interface q conduit end
    set_interface_property q EXPORT_OF sqrt.q

    add_interface en conduit end
    set_interface_property en EXPORT_OF sqrt.en

    add_interface areset conduit end
    set_interface_property areset EXPORT_OF sqrt.areset

    add_connection clk.out_clk sqrt.clk

    save_system acl_fsqrt.ip
}

# Run IP generation
create_fmadd
create_fdiv
create_fsqrt

puts "FPU IPs generated successfully!"
