module fifo_12b_256w_show_ahead (
		input  wire [11:0] data,  //  fifo_input.datain,  Data input of the memory.The data port is required for all FIFO operation.
		input  wire        wrreq, //            .wrreq,   wrreq input signal to request for write operation.The wrreq signal is required for all FIFO operation.
		input  wire        rdreq, //            .rdreq,   rdreq input signal to request for read operation.The rdreq signal is required for all FIFO operation.
		input  wire        clock, //            .clk,     Positive-edge-triggered clock.
		input  wire        aclr,  //            .aclr,    It is asynchronous reset.Assert this signal to clear all the output status ports, but the effect on the q output may vary for different FIFO configurations.
		output wire [11:0] q,     // fifo_output.dataout, Data output of the memory. This port is required for all FIFO operation.
		output wire [7:0]  usedw, //            .usedw,   Show the number of words stored in the FIFO.
		output wire        full,  //            .full,    When full signal is asserted, the FIFO IP core is considered full. Do not perform write request operation when the FIFO IP core is full.
		output wire        empty  //            .empty,   When empty signal is asserted, the FIFO IP core is considered empty.Do not perform read request operation when the FIFO IP core is empty.
	);
endmodule

