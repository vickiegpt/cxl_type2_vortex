// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//Legal Notice: (C)2023 Altera Corporation. All rights reserved.  Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

// turn off superfluous verilog processor warnings 
// altera message_level Level1 
// altera message_off 10034 10035 10036 10037 10230 10240 10030 13469 16735 16788 

module pcie_ed_MEM0_altera_avalon_onchip_memory2_1932_vi4l4uq (
                                                                // inputs:
                                                                 address,
                                                                 byteenable,
                                                                 chipselect,
                                                                 clk,
                                                                 clken,
                                                                 freeze,
                                                                 reset,
                                                                 reset_req,
                                                                 write,
                                                                 writedata,

                                                                // outputs:
                                                                 readdata
                                                              )
;

//  parameter INIT_FILE = "pcie_ed_MEM0_MEM0.hex";


  output  [1023: 0] readdata;
  input   [  7: 0] address;
  input   [127: 0] byteenable;
  input            chipselect;
  input            clk;
  input            clken;
  input            freeze;
  input            reset;
  input            reset_req;
  input            write;
  input   [1023: 0] writedata;


wire             clocken0;
wire             freeze_dummy_signal;
reg     [1023: 0] readdata;
wire    [1023: 0] readdata_ram;
wire             reset_dummy_signal;
wire             wren;
  assign reset_dummy_signal = reset;
  assign freeze_dummy_signal = freeze;
  always @(posedge clk)
    begin
      if (clken)
          readdata <= readdata_ram;
    end


  assign wren = chipselect & write;
  assign clocken0 = clken & ~reset_req;
  altsyncram the_altsyncram
    (
      .address_a (address),
      .byteena_a (byteenable),
      .clock0 (clk),
      .clocken0 (clocken0),
      .data_a (writedata),
      .q_a (readdata_ram),
      .wren_a (wren)
    );

  defparam the_altsyncram.byte_size = 8,
//           the_altsyncram.init_file = INIT_FILE,
           the_altsyncram.lpm_type = "altsyncram",
           the_altsyncram.maximum_depth = 256,
           the_altsyncram.numwords_a = 256,
           the_altsyncram.operation_mode = "SINGLE_PORT",
           the_altsyncram.outdata_reg_a = "UNREGISTERED",
           the_altsyncram.ram_block_type = "AUTO",
           the_altsyncram.read_during_write_mode_mixed_ports = "DONT_CARE",
           the_altsyncram.read_during_write_mode_port_a = "DONT_CARE",
           the_altsyncram.width_a = 1024,
           the_altsyncram.width_byteena_a = 128,
           the_altsyncram.widthad_a = 8;

  //s1, which is an e_avalon_slave
  //s2, which is an e_avalon_slave

endmodule

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL6KhPkU+n8DZPJuJMqsOEtSiN8+YguOdJAkRN5JDuzXtXVSD75opDHVYhu1lfX+ECgdJHDmlRUmB4kQAjBOw4RXpG3LZAdipLliKntqWFcfgZLOprfcOtxLYbpiE5d1QPlj+VHFhpNjLv6Ts66TNJqo6aqrPhBhlholS/olCOcR0ffnyIfaD6EaQBzxckHckxIjYwhqh8DQ9cLne/KkwH0RIaZsp6MKPCm3ro0DN4AflQy1df3rgQTcgbMgWjD0cMa+UTRWkSSRQT8rT50GVoLToOjH+j3zrJSnZIjY5ftTSfcos0bxybbkDdZkGqqUAANW8WMi8WJxKKlFHO0tglCp+hC6sGFPWldOQqXdXV9ODUuUhw/z1O6sgSqifz/voH4kofvXxDlU2+KGqdc2Tg/QjFHy6+ZogsHCCfPMY8emXzs4uPuOU7A205fwqaz51ngIyOq1G0evZzB17k12sSkU2e/XyHwMrO0fc+I8TzBN6Ug8ZGyukCCgYqVTeC0NTkkcckSueeP3qELN0HL29qYUIlYp95PPEFPwy3+Ex53q8mY2Qtse6dmLpbhbTqcWGcilVNabPYE+A1V4KIkmCeR9i+a+KwwgQdBcwZ6WHrMs0OoHvDi962EpT4O0kDcgkLrv/u5hMOEttw1dxTnyAPGyUoaJWefqSn3LDgP+qdARBf9Rz4wGX3DDIrPh+Tb6/rTUxqQsSZQUOZQn/3Xqdd9Hjc7jUGiDvAAsjKM39YXJ4CD4fA4ORPPt6+UGgrjTZvA/5UAuOAvMGczlVwh42zWY"
`endif