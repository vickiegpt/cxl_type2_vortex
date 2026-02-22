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


// Copyright 2024 Intel Corporation.
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
//
///////////////////////////////////////////////////////////////////////
//-------------------------------------------------------------------------
//  Global Defines
// ------------------------------------------------------------------------
//
package cafu_csr0_gbl_pkg;

/* This define configures the design for the design validation environment of a single bbs slice.
   This mode is not intended for customer use and may result in unexpected behaviour if set.
 */
//`define INTEL_ONLY_CXLIPDEV  1


endpackage : cafu_csr0_gbl_pkg
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcfr6TF38EW5l93UcdpMfeilXNh/Dkq7MTDDJ/71U5Z4R6260YhtVFl7wwV3m8Y1UcZkrw28Q777ubY7QU9YN6mqZzH8Io2DdNNtomv7CnCKx+4gGGeXendj9mifztgcviw1JpdSnSlzwd8R9QrzNJIXQYsCAWHGye/m6LGIwYRIZrA5D8wEroZydnealCgldj9mAE6zFYMXhtWr4YkzI8yo+8vpICX5KH7mcnsQueIdtRAQVAfkzsm36B27+NopuS7hzOs6PhwwXxajlNZdRS/+u/LEXIvt103z6frRViSslmlEVOM2ozQ822ra0X2pm8MByTLs/pROVABzEhHnPdgVS8IjtNrqlN0ZPmB7yIZqEPE4jmUE495DIE0xpHGsemRmwY249MDjm3veY1NHJ1G/bgxzW18lRNCPycfaDC9RdZtqAJWGHEg9H0fif8PUKNso+yzFCoDzEJtX4gReqa4wBXKlxbrgm4nU9qfm0u0QnOCUNJksueOVXwS+xQgva3HvlrpvBgaIcpeh5aCX9FcWLx9qop3tl6eHEaU2xaiXEAbhGWeKLGFPRTv/OfkCTLCJ5eTllUWu1qijJ/kUHp7M0noXttzSmqyPXTNfYp0iCQ4eudBpxjPHml5w8U+KDfk7pG4tTrv0UwFBWTQT9Nh2HMaFuq5aA0E383dLQEuJtSYryEt36zN80kFneplQ6vasGgw85FshmFb1vBmFE38tFC72OpFb+z60aHOZkQLmu50WOK6Ll6LUi5FkNJ+hXu5KpARivr70to7BK56kt3x4"
`endif