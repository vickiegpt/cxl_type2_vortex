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
//
///////////////////////////////////////////////////////////////////////
// Creation Date : Feb, 2023
// Description   : SBCNT/DBCNT 



module mc_devmem_top 
import mc_ecc_pkg::*; 
(
  input  logic                                    clk,
  input  logic                                    rst,

  input   mc_ecc_pkg::mc_devmem_if_t              mc_devmem_if,
  output  mc_ecc_pkg::mc_err_cnt_t                mc_err_cnt

    );


  logic [32:0]  mcRdDataDBECnt_Q;
  logic [3:0]   mcRdDataDBESum;
  logic         mcRdDataNewDBE_Q;
  logic         mcRdDataNewPoisonRtn_Q;
  logic         mcRdDataNewSBE_Q;
  logic [32:0]  mcRdDataPoisonRtnCnt_Q;
  logic [32:0]  mcRdDataSBECnt_Q;
  logic [3:0]   mcRdDataSBESum;
  logic         mcErrOnPartial_Q;

  // Generate sum of SBE[7:0] and DBE[7:0]
  always_comb begin
    mcRdDataSBESum = '0;
    mcRdDataDBESum = '0;

    for (int i=0; i<8; i++) begin
      mcRdDataSBESum += mc_devmem_if.RdDataECC.SBE[i];
      mcRdDataDBESum += mc_devmem_if.RdDataECC.DBE[i];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      mcRdDataSBECnt_Q <= '0;
      mcRdDataNewSBE_Q <= 1'b0;
    end
    else if (mc_devmem_if.RdDataECC.Valid & (|mc_devmem_if.RdDataECC.SBE)) begin
      mcRdDataSBECnt_Q <= mcRdDataSBECnt_Q + mcRdDataSBESum;
      mcRdDataNewSBE_Q <= 1'b1;  // Update channel aggregated count
    end
    else if (mcRdDataNewSBE_Q) begin
      mcRdDataNewSBE_Q <= 1'b0;
    end
  end

  // - If all DBE instances report error, treat as data written to memory with poison=1
  //   - Not treated as a DBE error case
  //     - Increment "poison return" count
  //     - Do not increment DBE count
  //   - Note: Read data returned to host will have poison=1 (any DBE causes poison=1)
  // - If some (not all) DBE instances report error, treat as data written to memory with poison=0
  //   - Treated as a DBE error case
  //     - Increment DBE count
  //     - Increment "poison return" count
  //   - Note: Read data returned to host will have poison=1 (any DBE causes poison=1)

  //1-8 DBEs should increment poison counter
  always_ff @(posedge clk) begin
    if (rst) begin
      mcRdDataPoisonRtnCnt_Q <= '0;
      mcRdDataNewPoisonRtn_Q <= 1'b0;
    end
    else if (mc_devmem_if.RdDataValid & (|mc_devmem_if.RdDataECC.DBE)) begin
      mcRdDataPoisonRtnCnt_Q <= mcRdDataPoisonRtnCnt_Q + 'd1;
      mcRdDataNewPoisonRtn_Q <= 1'b1;  // Update channel aggregated count
    end
    else if (mcRdDataNewPoisonRtn_Q) begin
      mcRdDataNewPoisonRtn_Q <= 1'b0;
    end
  end

  //1-7 DBEs should increment DBE counter. Specifically, 8DBEs does not increment DBE counter
  always_ff @(posedge clk) begin
    if (rst) begin
      mcRdDataDBECnt_Q <= '0;
      mcRdDataNewDBE_Q <= 1'b0;
    end
    else if (mc_devmem_if.RdDataECC.Valid & (|mc_devmem_if.RdDataECC.DBE) & (~&mc_devmem_if.RdDataECC.DBE)) begin
      mcRdDataDBECnt_Q <= mcRdDataDBECnt_Q + mcRdDataDBESum;
      mcRdDataNewDBE_Q <= 1'b1;  // Update channel aggregated count
    end
    else if (mcRdDataNewDBE_Q) begin
      mcRdDataNewDBE_Q <= 1'b0;
    end
  end

  // Create indicator for mbox logic to know if Err indicator is for partial write
  //  From mc_channel_adapter:
  //      If both mc2iafu_readdatavalid_eclk == 1 and mc2iafu_ecc_err_valid_eclk == 1
  //        then *ecc_err_* are related to mc2iafu_readdata_eclk
  //      If mc2iafu_readdatavalid_eclk == 0 and mc2iafu_ecc_err_valid_eclk == 1
  //        then *ecc_err_* are related to partial write. "Partial write" functionality is realised as read-modify-write function.

  always_ff @(posedge clk) begin
    if (rst) begin
      mcErrOnPartial_Q <= '0;
    end
    else if (mc_devmem_if.RdDataECC.Valid & ~mc_devmem_if.RdDataValid) begin
      mcErrOnPartial_Q <= '1;
    end
    else begin
      mcErrOnPartial_Q <= '0;
    end
  end

  assign mc_err_cnt.SBECnt       = mcRdDataSBECnt_Q;
  assign mc_err_cnt.DBECnt       = mcRdDataDBECnt_Q;
  assign mc_err_cnt.PoisonRtnCnt = mcRdDataPoisonRtnCnt_Q;

  assign mc_err_cnt.NewSBE       = mcRdDataNewSBE_Q;
  assign mc_err_cnt.NewDBE       = mcRdDataNewDBE_Q;
  assign mc_err_cnt.NewPoisonRtn = mcRdDataNewPoisonRtn_Q;
  assign mc_err_cnt.NewPartialWr = mcErrOnPartial_Q;
  
  assign mc_err_cnt.DevAddr      = '1;



endmodule
                 
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL5tVbi6wBykQgYw/L5h5oCbIxM158hFSWDQjHY2sN4tHBjuksau//Wu/kvoqEGjr9B5z4frRm/iy83sKkjGoscVhE3yKJDKoHf5Tb/7kXpF8augEjZgDCm9Nu7iVwfGke9UuuZZzpg56ip6Fz+oQb+Z4gMv77hP83NejSjhwgJMf6fQi2Jwrz9pXIuHol9XGDn8ViHuMKyn/4g3Q85O720eSkAffjDodF6Iyovsj8mK43MEFNJEVTtCW2Cg2o2k8qefurx+Eh4smodLj+srT3ZcxXM0kbQW/iIWze7G6rJBCZApH3miI6fijAoTD8qEycD2zNm0pdRpRO5AsA5sAmUvTVeA7b1/KhyWNIE5hX8c7N2o7o/+7n668qWEL1ldRMm/qf1kdgE2G2ufxNfmuNF3WcMj7ZKBl97as8IcbR0Nc0vW6UrFTbyxn4TCl9OYoTjJ1l9tRsnvtwjp6UuRR4P5lbpU6VSuvKnuLPI3Mc1xKrdgHxuhMuLZUyo/zv8p6ZqrhCHxF4KX1zopFLS5QALkS0xeFYTC2CYlhaq7AVWTRi9HC9pMginV2pzzRzYxmDiP6WSWfhiv3PTSe2MSrzg/IeqRnIAPPNYu7f7OS39CFXumEC55G9blu/xt8ASAoJOBOvLocyca6JGQ2oaouu8RX93GvRKjQnRgC+KOg3BZ/C6A+e7k4GtJxHXWs3dnI/44oZ8zWW4tRpBsxgChmaOwIf9nk1Bmy3/R+6CFlO9hKOThupBDFMHMny4C3q76ZcECT4lgCFQlaVGdYjWOzxnW"
`endif