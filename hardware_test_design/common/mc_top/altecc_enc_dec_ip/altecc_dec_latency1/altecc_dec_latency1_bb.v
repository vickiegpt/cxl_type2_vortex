module altecc_dec_latency1 (
		input  wire [71:0] data,          //          data.data,          Data input port. The size of the input port depends on the WIDTH_CODEWORD parameter value.
		output wire [63:0] q,             //             q.q,             Decoded data output port. The size of the output port depends on the WIDTH_DATAWORD parameter value.
		output wire        err_corrected, // err_corrected.err_corrected, Flag signal to reflect the status of data received. Denotes single-bit error found and corrected. You can use the data because it has already been corrected.
		output wire        err_detected,  //  err_detected.err_detected,  Flag signal to reflect the status of data received and specifies any errors found.
		output wire        err_fatal,     //     err_fatal.err_fatal,     Flag signal to reflect the status of data received. Denotes double-bit error found, but not corrected. You must not use the data if this signal is asserted.
		output wire        syn_e,         //         syn_e.syn_e,         An output signal which will go high whenever a single-bit error is detected on the parity bits.
		input  wire        clock          //         clock.clock,         Clock input port that provides the clock signal to synchronize the encoding operation. The clock port is required when the LPM_PIPELINE value is greater than 0.
	);
endmodule

