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

module cxl_io_image_version (data_out);
    output [31:0] data_out;
    assign data_out[15:0] = 16'h4202; //CXL IO version
    assign data_out[31:16] = 16'h5381;
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "XFrUMns8Fu6xzciiUKfNSUJqdm5/YAOWzSRd9PXG1U3ynGg1aOoqSyaMvrkCPE+ZpR3rMMe0byG2yUWPP8Sqo/kU6eQrLCR648HpYyruBOr9HMDgtUcq1fvQOdB66sNoEcaT1UHLj0keHVs4MrWLOJ734t5GK79+rG3Jqb3f7JH1NAEeZcOzfSQ3ksk0o+5JqKOKoqRx3trMUrmz8+RXfGhPdyzBVHCyBYngV6sbJpg1R2q1HpnMZ42unvfxsZ5DC1HWcXsVptYNnh1/8OV9cxV8oIF1EXjCem+bLyN9Aqy7Nm+/2YCeGeT5On59RJBsNv4VdTQksV3ddJyOpBoYbfBxpkw39Mi0oBUUtoCZtZ5d7ef9ROsQ06rATcSR3pwP7XMVV+Fuep3jozED0nXa7v521y1AhuKYJPB231N8v3AHPw6vk6BAsgPBa3adVdMuNI8OvqM6LgLbvnFw+J9nl15qMQZLjTKEPm7X4N2M9jE2QR4/WTtnUzL0fymtvx4THOmNua6kTk5k8UsggO2WNclLchP4LcnmOdP2Yyuenv6XM/oz7HuOk4BAcaOPyb8punipPVTf6z+1/1kq222TmLL/XhHc+TW7xIn4bwTGuPOxorsLQjLn2nXy/rV6pEKll+zorZ9zyX9HY8a3E1u1+wTB5oD9QZCEN/4++u5f/lvisVI5hKnoPerbJQ85KwIrAiJ4X+lBcwUaAAy2383CvXIiu+3gF5BCxT2o2buX2nbiegDRL7tPrakSA4JLexD2WAEqLCx2dsq8UBI1o0OJpwTZ/gnBJWdu0TsdZL1SXsv4OlYnPiG9tyQaH3LVOvCfJrRud2tjPFTHNVJfjJDsYzY/jf/IYRVjjg3+pqzW9vlteahG6sAxBhPJAS7MpRAE8qk9kBL66EGO5rlMUZ7C0hlpNRqviEYtm7iCc7xCiyU6eHmicWEalEn9xt2rX1+zrrGAd4yFPx2mrYtzF4e//ptFaWCXU7ff//1mTAUxo6QBxSiwHdbdH5/JUEQDTIhq"
`endif
