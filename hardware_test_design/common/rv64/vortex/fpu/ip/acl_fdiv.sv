// Intel FPGA Floating-point Division wrapper
// Implements: q = a / b (single precision IEEE-754)
// Latency: 15 cycles
// Target: Intel Agilex 7 - Synthesis friendly version

`timescale 1ns / 1ps

module acl_fdiv (
    input  wire        clk,
    input  wire        areset,
    input  wire        en,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] q
);

    // Pipeline depth for division operation
    localparam LATENCY = 15;

    // Extract IEEE-754 fields
    wire        sign_a = a[31];
    wire [7:0]  exp_a  = a[30:23];
    wire [22:0] mant_a = a[22:0];

    wire        sign_b = b[31];
    wire [7:0]  exp_b  = b[30:23];
    wire [22:0] mant_b = b[22:0];

    // Implicit 1 for normalized numbers
    wire [23:0] mant_a_full = (exp_a != 0) ? {1'b1, mant_a} : {1'b0, mant_a};
    wire [23:0] mant_b_full = (exp_b != 0) ? {1'b1, mant_b} : {1'b0, mant_b};

    // Pipeline registers
    reg [31:0] pipe [0:LATENCY-1];

    // Compute result sign and exponent
    wire result_sign = sign_a ^ sign_b;
    wire [8:0] result_exp_raw = {1'b0, exp_a} - {1'b0, exp_b} + 9'd127;

    // Division using iterative Newton-Raphson or direct division
    // For synthesis, we use a simple shift-subtract divider concept
    // Pipeline the computation

    // Stage 0: Register inputs and compute initial values
    reg [31:0] a_r0, b_r0;
    reg        sign_r0;
    reg [8:0]  exp_r0;
    reg [47:0] dividend_r0;  // Extended for precision
    reg [23:0] divisor_r0;

    always @(posedge clk) begin
        if (areset) begin
            a_r0 <= 32'h0;
            b_r0 <= 32'h0;
            sign_r0 <= 1'b0;
            exp_r0 <= 9'h0;
            dividend_r0 <= 48'h0;
            divisor_r0 <= 24'h0;
        end else if (en) begin
            a_r0 <= a;
            b_r0 <= b;
            sign_r0 <= result_sign;
            exp_r0 <= result_exp_raw;
            dividend_r0 <= {mant_a_full, 24'h0};
            divisor_r0 <= mant_b_full;
        end
    end

    // Stages 1-13: Iterative division (shift-subtract)
    reg [47:0] quotient_r [1:13];
    reg [47:0] remainder_r [1:13];
    reg [23:0] divisor_r [1:13];
    reg        sign_r [1:13];
    reg [8:0]  exp_r [1:13];
    reg [31:0] b_r [1:13];

    genvar i;
    generate
        for (i = 1; i <= 13; i = i + 1) begin : div_stages
            always @(posedge clk) begin
                if (areset) begin
                    quotient_r[i] <= 48'h0;
                    remainder_r[i] <= 48'h0;
                    divisor_r[i] <= 24'h0;
                    sign_r[i] <= 1'b0;
                    exp_r[i] <= 9'h0;
                    b_r[i] <= 32'h0;
                end else if (en) begin
                    if (i == 1) begin
                        // First iteration
                        if (dividend_r0 >= {24'h0, divisor_r0}) begin
                            quotient_r[1] <= {47'h0, 1'b1};
                            remainder_r[1] <= dividend_r0 - {24'h0, divisor_r0};
                        end else begin
                            quotient_r[1] <= 48'h0;
                            remainder_r[1] <= dividend_r0;
                        end
                        divisor_r[1] <= divisor_r0;
                        sign_r[1] <= sign_r0;
                        exp_r[1] <= exp_r0;
                        b_r[1] <= b_r0;
                    end else begin
                        // Subsequent iterations
                        if ({remainder_r[i-1][46:0], 1'b0} >= {24'h0, divisor_r[i-1]}) begin
                            quotient_r[i] <= {quotient_r[i-1][46:0], 1'b1};
                            remainder_r[i] <= {remainder_r[i-1][46:0], 1'b0} - {24'h0, divisor_r[i-1]};
                        end else begin
                            quotient_r[i] <= {quotient_r[i-1][46:0], 1'b0};
                            remainder_r[i] <= {remainder_r[i-1][46:0], 1'b0};
                        end
                        divisor_r[i] <= divisor_r[i-1];
                        sign_r[i] <= sign_r[i-1];
                        exp_r[i] <= exp_r[i-1];
                        b_r[i] <= b_r[i-1];
                    end
                end
            end
        end
    endgenerate

    // Stage 14: Normalize and pack result
    reg [31:0] result_r14;

    always @(posedge clk) begin
        if (areset) begin
            result_r14 <= 32'h0;
        end else if (en) begin
            // Check for special cases
            if (b_r[13][30:0] == 31'h0) begin
                // Division by zero
                result_r14 <= {sign_r[13], 8'hFF, 23'h0}; // Inf
            end else if (exp_r[13][8]) begin
                // Underflow
                result_r14 <= {sign_r[13], 31'h0}; // Zero
            end else if (exp_r[13] >= 9'd255) begin
                // Overflow
                result_r14 <= {sign_r[13], 8'hFF, 23'h0}; // Inf
            end else begin
                // Normal result - extract mantissa from quotient
                result_r14 <= {sign_r[13], exp_r[13][7:0], quotient_r[13][22:0]};
            end
        end
    end

    // Stage 15: Output register
    reg [31:0] result_r15;

    always @(posedge clk) begin
        if (areset) begin
            result_r15 <= 32'h0;
        end else if (en) begin
            result_r15 <= result_r14;
        end
    end

    assign q = result_r15;

endmodule
