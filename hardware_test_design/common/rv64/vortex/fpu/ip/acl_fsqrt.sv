// Intel FPGA Floating-point Square Root wrapper
// Implements: q = sqrt(a) (single precision IEEE-754)
// Latency: 10 cycles
// Target: Intel Agilex 7 - Synthesis friendly version

`timescale 1ns / 1ps

module acl_fsqrt (
    input  wire        clk,
    input  wire        areset,
    input  wire        en,
    input  wire [31:0] a,
    output wire [31:0] q
);

    // Pipeline depth for sqrt operation
    localparam LATENCY = 10;

    // Extract IEEE-754 fields
    wire        sign_a = a[31];
    wire [7:0]  exp_a  = a[30:23];
    wire [22:0] mant_a = a[22:0];

    // Implicit 1 for normalized numbers
    wire [23:0] mant_a_full = (exp_a != 0) ? {1'b1, mant_a} : {1'b0, mant_a};

    // Result exponent: (exp_a - 127) / 2 + 127 = (exp_a + 127) / 2
    // For odd exponent, shift mantissa left by 1 bit
    wire exp_odd = exp_a[0];
    wire [7:0] result_exp = (exp_a + 8'd127) >> 1;

    // Pipeline registers for sqrt computation
    // Using non-restoring square root algorithm

    // Stage 0: Register inputs
    reg [31:0] a_r0;
    reg [7:0]  exp_r0;
    reg [47:0] radicand_r0;  // Extended mantissa for sqrt
    reg        is_special_r0;
    reg [31:0] special_result_r0;

    always @(posedge clk) begin
        if (areset) begin
            a_r0 <= 32'h0;
            exp_r0 <= 8'h0;
            radicand_r0 <= 48'h0;
            is_special_r0 <= 1'b0;
            special_result_r0 <= 32'h0;
        end else if (en) begin
            a_r0 <= a;
            exp_r0 <= result_exp;

            // Adjust radicand based on odd/even exponent
            if (exp_odd)
                radicand_r0 <= {mant_a_full, 24'h0} << 1;
            else
                radicand_r0 <= {mant_a_full, 24'h0};

            // Check for special cases
            if (sign_a && (exp_a != 0 || mant_a != 0)) begin
                // Negative number (not -0)
                is_special_r0 <= 1'b1;
                special_result_r0 <= 32'h7FC00000; // NaN
            end else if (exp_a == 8'hFF) begin
                // Inf or NaN
                is_special_r0 <= 1'b1;
                if (mant_a == 0)
                    special_result_r0 <= sign_a ? 32'h7FC00000 : a; // NaN for -Inf, Inf for +Inf
                else
                    special_result_r0 <= a; // NaN passthrough
            end else if (exp_a == 0 && mant_a == 0) begin
                // Zero
                is_special_r0 <= 1'b1;
                special_result_r0 <= a; // Return same zero
            end else begin
                is_special_r0 <= 1'b0;
                special_result_r0 <= 32'h0;
            end
        end
    end

    // Stages 1-8: Non-restoring square root iterations
    reg [47:0] root_r [1:8];
    reg [47:0] remainder_r [1:8];
    reg [7:0]  exp_r_pipe [1:8];
    reg        is_special_r [1:8];
    reg [31:0] special_result_r [1:8];

    genvar i;
    generate
        for (i = 1; i <= 8; i = i + 1) begin : sqrt_stages
            always @(posedge clk) begin
                if (areset) begin
                    root_r[i] <= 48'h0;
                    remainder_r[i] <= 48'h0;
                    exp_r_pipe[i] <= 8'h0;
                    is_special_r[i] <= 1'b0;
                    special_result_r[i] <= 32'h0;
                end else if (en) begin
                    is_special_r[i] <= (i == 1) ? is_special_r0 : is_special_r[i-1];
                    special_result_r[i] <= (i == 1) ? special_result_r0 : special_result_r[i-1];
                    exp_r_pipe[i] <= (i == 1) ? exp_r0 : exp_r_pipe[i-1];

                    if (i == 1) begin
                        // First iteration
                        if (radicand_r0[47:46] >= 2'b01) begin
                            root_r[1] <= 48'h000000000001;
                            remainder_r[1] <= {radicand_r0[45:0], 2'b00} - 48'h000000000001;
                        end else begin
                            root_r[1] <= 48'h0;
                            remainder_r[1] <= {radicand_r0[45:0], 2'b00};
                        end
                    end else begin
                        // Subsequent iterations using non-restoring method
                        // trial = 4*remainder + 2 - (4*root + 1)
                        // Simplified: check if remainder >= 0 after subtraction
                        if (!remainder_r[i-1][47]) begin
                            // Remainder positive
                            root_r[i] <= {root_r[i-1][46:0], 1'b1};
                            remainder_r[i] <= {remainder_r[i-1][45:0], 2'b00} -
                                              {root_r[i-1][44:0], 3'b001};
                        end else begin
                            // Remainder negative
                            root_r[i] <= {root_r[i-1][46:0], 1'b0};
                            remainder_r[i] <= {remainder_r[i-1][45:0], 2'b00} +
                                              {root_r[i-1][44:0], 3'b111};
                        end
                    end
                end
            end
        end
    endgenerate

    // Stage 9: Final normalization
    reg [31:0] result_r9;

    always @(posedge clk) begin
        if (areset) begin
            result_r9 <= 32'h0;
        end else if (en) begin
            if (is_special_r[8]) begin
                result_r9 <= special_result_r[8];
            end else begin
                // Pack result
                result_r9 <= {1'b0, exp_r_pipe[8], root_r[8][22:0]};
            end
        end
    end

    // Stage 10: Output register
    reg [31:0] result_r10;

    always @(posedge clk) begin
        if (areset) begin
            result_r10 <= 32'h0;
        end else if (en) begin
            result_r10 <= result_r9;
        end
    end

    assign q = result_r10;

endmodule
