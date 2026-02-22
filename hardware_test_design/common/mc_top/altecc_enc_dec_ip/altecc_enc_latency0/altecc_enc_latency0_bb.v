module altecc_enc_latency0 (
		input  wire [63:0] data, // data.data, Data input port. The size of the input port depends on the WIDTH_DATAWORD parameter value. The data port contains the raw data to be encoded.
		output wire [71:0] q     //    q.q,    Encoded data output port. The size of the output port depends on the WIDTH_CODEWORD parameter value.
	);
endmodule

