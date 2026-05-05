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


// Copyright 2022 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module cxl_io_build_version (data_out);
    output [31:0] data_out;
    assign data_out[31] = 1'h1; //1 - debug, 0 - release
    assign data_out[30:0] = 30'h00000000;
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "XFrUMns8Fu6xzciiUKfNSUJqdm5/YAOWzSRd9PXG1U3ynGg1aOoqSyaMvrkCPE+ZpR3rMMe0byG2yUWPP8Sqo/kU6eQrLCR648HpYyruBOr9HMDgtUcq1fvQOdB66sNoEcaT1UHLj0keHVs4MrWLOJ734t5GK79+rG3Jqb3f7JH1NAEeZcOzfSQ3ksk0o+5JqKOKoqRx3trMUrmz8+RXfGhPdyzBVHCyBYngV6sbJpjqMMoJO5EhNaQriOqSyLJuItZPJLkeTB5GDXZc2lLlmHZpG5FzUj2rKbyQ8dT9gyUKPX5logC5yGVJzUW3otrhlYtl6f0jkYYV6xxHWsNpgneqkeOnEqJ8ORLDHoC0FuKFDEy5hZSHEJ6gW6QwVVGcL5i8lPyKpNHQceg2Q7a62Ym8Why2SyRr7W8HceTzIgcS8/jZ8vUJWh2diyNLaei/UPf6Fj6gjW/gvwZYOU168uvrB8RrAMAMfHsnL9+PPxWZd0YdtU6lUVP6I8+Jwy5ULEzX+qDxCSB81unxHTDLGy/KjRpzL0YUBHEKSamzaDjvRXrgjNhKgkjonK3nqyi6To5z+tQNeWkNMMcvtuJ1qWudQruELG+TYv/cUi9eiX6kvH26CjtKO6fQ2ogc5UkTU03KrKNY/sIjBroByjeJv61EEbXC3nJHMsSkgz7zRbQLBFHoCewAZLvre4JdWfgEG9QD6DUhLt0UNHwbk7OL5UNwL9Gmgk+8Je3uYEyWpFRrbmK6Qvw3Cf/qdli/+sbY09pfF3P3jlVx/GcTwlSkIBo+L/rrvb79Ts+64UO+0cQfWxRsARUypWm0oXpu1QhwGsEpZPqof72HvSkM+6wUzO/tYkM4c8hGRUtyTppBOcMcyg99sYRHxRBtvrXq1KSinKg2yLAx0Rv+OA2WMY++BnzBA+hHoUM8xN08tKAJLzqTkRdPtoeTeKufnyjWuCyfd0dEXloCtgpZ2fXFARxERK3GAPjnIvAPNL31OfXNx6BNfu+YD+8g6f6ctZxEbFwF"
`endif