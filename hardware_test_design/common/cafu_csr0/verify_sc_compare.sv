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

/*  Page 602 of CXL 2.0 Spec
*/

module verify_sc_compare
(
    input [511:0]   received_in,
    input [511:0]   expected_in,
    input [63:0]    byte_mask_reg_in,
    
    output logic [63:0]  compare_out
);
   
logic [511:0]  compare_z;

/* June 2024 : LINT cleanup
   https://www.yunhook.top:8145/spyglass/htmlhelp/index.html#page/spyglass/WRN_70.htm
   Lint error where IEEE deprecated standalone generate statements (for some stupid reason)
   having basing for loop with int causes "should haveconstant index" error on compile.
*/
/*
always_comb
begin
  for( int i = 0; i<512; i=i+1 )
  begin
    compare_z[i] = ( received_in[i] ^ expected_in[i] );
  end
end
*/
    /*
     *  do an binary OR of each byte to see if it has a mismatch but then
     *  AND that result with the byte mask index of that byte to see if
     *  it is a byte that is enabled
     */
/*
always_comb
begin
  for( int j=0; j<512; j=j+8 )
  begin
    compare_out[j/8] = |compare_z[(j+7):j] & byte_mask_reg_in[j/8];
  end
end
*/

always_comb
begin
     compare_z[0] = ( received_in[0] ^ expected_in[0] );
     compare_z[1] = ( received_in[1] ^ expected_in[1] );
     compare_z[2] = ( received_in[2] ^ expected_in[2] );
     compare_z[3] = ( received_in[3] ^ expected_in[3] );
     compare_z[4] = ( received_in[4] ^ expected_in[4] );
     compare_z[5] = ( received_in[5] ^ expected_in[5] );
     compare_z[6] = ( received_in[6] ^ expected_in[6] );
     compare_z[7] = ( received_in[7] ^ expected_in[7] );
     compare_z[8] = ( received_in[8] ^ expected_in[8] );
     compare_z[9] = ( received_in[9] ^ expected_in[9] );
     compare_z[10] = ( received_in[10] ^ expected_in[10] );
     compare_z[11] = ( received_in[11] ^ expected_in[11] );
     compare_z[12] = ( received_in[12] ^ expected_in[12] );
     compare_z[13] = ( received_in[13] ^ expected_in[13] );
     compare_z[14] = ( received_in[14] ^ expected_in[14] );
     compare_z[15] = ( received_in[15] ^ expected_in[15] );
     compare_z[16] = ( received_in[16] ^ expected_in[16] );
     compare_z[17] = ( received_in[17] ^ expected_in[17] );
     compare_z[18] = ( received_in[18] ^ expected_in[18] );
     compare_z[19] = ( received_in[19] ^ expected_in[19] );
     compare_z[20] = ( received_in[20] ^ expected_in[20] );
     compare_z[21] = ( received_in[21] ^ expected_in[21] );
     compare_z[22] = ( received_in[22] ^ expected_in[22] );
     compare_z[23] = ( received_in[23] ^ expected_in[23] );
     compare_z[24] = ( received_in[24] ^ expected_in[24] );
     compare_z[25] = ( received_in[25] ^ expected_in[25] );
     compare_z[26] = ( received_in[26] ^ expected_in[26] );
     compare_z[27] = ( received_in[27] ^ expected_in[27] );
     compare_z[28] = ( received_in[28] ^ expected_in[28] );
     compare_z[29] = ( received_in[29] ^ expected_in[29] );
     compare_z[30] = ( received_in[30] ^ expected_in[30] );
     compare_z[31] = ( received_in[31] ^ expected_in[31] );
     compare_z[32] = ( received_in[32] ^ expected_in[32] );
     compare_z[33] = ( received_in[33] ^ expected_in[33] );
     compare_z[34] = ( received_in[34] ^ expected_in[34] );
     compare_z[35] = ( received_in[35] ^ expected_in[35] );
     compare_z[36] = ( received_in[36] ^ expected_in[36] );
     compare_z[37] = ( received_in[37] ^ expected_in[37] );
     compare_z[38] = ( received_in[38] ^ expected_in[38] );
     compare_z[39] = ( received_in[39] ^ expected_in[39] );
     compare_z[40] = ( received_in[40] ^ expected_in[40] );
     compare_z[41] = ( received_in[41] ^ expected_in[41] );
     compare_z[42] = ( received_in[42] ^ expected_in[42] );
     compare_z[43] = ( received_in[43] ^ expected_in[43] );
     compare_z[44] = ( received_in[44] ^ expected_in[44] );
     compare_z[45] = ( received_in[45] ^ expected_in[45] );
     compare_z[46] = ( received_in[46] ^ expected_in[46] );
     compare_z[47] = ( received_in[47] ^ expected_in[47] );
     compare_z[48] = ( received_in[48] ^ expected_in[48] );
     compare_z[49] = ( received_in[49] ^ expected_in[49] );
     compare_z[50] = ( received_in[50] ^ expected_in[50] );
     compare_z[51] = ( received_in[51] ^ expected_in[51] );
     compare_z[52] = ( received_in[52] ^ expected_in[52] );
     compare_z[53] = ( received_in[53] ^ expected_in[53] );
     compare_z[54] = ( received_in[54] ^ expected_in[54] );
     compare_z[55] = ( received_in[55] ^ expected_in[55] );
     compare_z[56] = ( received_in[56] ^ expected_in[56] );
     compare_z[57] = ( received_in[57] ^ expected_in[57] );
     compare_z[58] = ( received_in[58] ^ expected_in[58] );
     compare_z[59] = ( received_in[59] ^ expected_in[59] );
     compare_z[60] = ( received_in[60] ^ expected_in[60] );
     compare_z[61] = ( received_in[61] ^ expected_in[61] );
     compare_z[62] = ( received_in[62] ^ expected_in[62] );
     compare_z[63] = ( received_in[63] ^ expected_in[63] );
     compare_z[64] = ( received_in[64] ^ expected_in[64] );
     compare_z[65] = ( received_in[65] ^ expected_in[65] );
     compare_z[66] = ( received_in[66] ^ expected_in[66] );
     compare_z[67] = ( received_in[67] ^ expected_in[67] );
     compare_z[68] = ( received_in[68] ^ expected_in[68] );
     compare_z[69] = ( received_in[69] ^ expected_in[69] );
     compare_z[70] = ( received_in[70] ^ expected_in[70] );
     compare_z[71] = ( received_in[71] ^ expected_in[71] );
     compare_z[72] = ( received_in[72] ^ expected_in[72] );
     compare_z[73] = ( received_in[73] ^ expected_in[73] );
     compare_z[74] = ( received_in[74] ^ expected_in[74] );
     compare_z[75] = ( received_in[75] ^ expected_in[75] );
     compare_z[76] = ( received_in[76] ^ expected_in[76] );
     compare_z[77] = ( received_in[77] ^ expected_in[77] );
     compare_z[78] = ( received_in[78] ^ expected_in[78] );
     compare_z[79] = ( received_in[79] ^ expected_in[79] );
     compare_z[80] = ( received_in[80] ^ expected_in[80] );
     compare_z[81] = ( received_in[81] ^ expected_in[81] );
     compare_z[82] = ( received_in[82] ^ expected_in[82] );
     compare_z[83] = ( received_in[83] ^ expected_in[83] );
     compare_z[84] = ( received_in[84] ^ expected_in[84] );
     compare_z[85] = ( received_in[85] ^ expected_in[85] );
     compare_z[86] = ( received_in[86] ^ expected_in[86] );
     compare_z[87] = ( received_in[87] ^ expected_in[87] );
     compare_z[88] = ( received_in[88] ^ expected_in[88] );
     compare_z[89] = ( received_in[89] ^ expected_in[89] );
     compare_z[90] = ( received_in[90] ^ expected_in[90] );
     compare_z[91] = ( received_in[91] ^ expected_in[91] );
     compare_z[92] = ( received_in[92] ^ expected_in[92] );
     compare_z[93] = ( received_in[93] ^ expected_in[93] );
     compare_z[94] = ( received_in[94] ^ expected_in[94] );
     compare_z[95] = ( received_in[95] ^ expected_in[95] );
     compare_z[96] = ( received_in[96] ^ expected_in[96] );
     compare_z[97] = ( received_in[97] ^ expected_in[97] );
     compare_z[98] = ( received_in[98] ^ expected_in[98] );
     compare_z[99] = ( received_in[99] ^ expected_in[99] );
     compare_z[100] = ( received_in[100] ^ expected_in[100] );
     compare_z[101] = ( received_in[101] ^ expected_in[101] );
     compare_z[102] = ( received_in[102] ^ expected_in[102] );
     compare_z[103] = ( received_in[103] ^ expected_in[103] );
     compare_z[104] = ( received_in[104] ^ expected_in[104] );
     compare_z[105] = ( received_in[105] ^ expected_in[105] );
     compare_z[106] = ( received_in[106] ^ expected_in[106] );
     compare_z[107] = ( received_in[107] ^ expected_in[107] );
     compare_z[108] = ( received_in[108] ^ expected_in[108] );
     compare_z[109] = ( received_in[109] ^ expected_in[109] );
     compare_z[110] = ( received_in[110] ^ expected_in[110] );
     compare_z[111] = ( received_in[111] ^ expected_in[111] );
     compare_z[112] = ( received_in[112] ^ expected_in[112] );
     compare_z[113] = ( received_in[113] ^ expected_in[113] );
     compare_z[114] = ( received_in[114] ^ expected_in[114] );
     compare_z[115] = ( received_in[115] ^ expected_in[115] );
     compare_z[116] = ( received_in[116] ^ expected_in[116] );
     compare_z[117] = ( received_in[117] ^ expected_in[117] );
     compare_z[118] = ( received_in[118] ^ expected_in[118] );
     compare_z[119] = ( received_in[119] ^ expected_in[119] );
     compare_z[120] = ( received_in[120] ^ expected_in[120] );
     compare_z[121] = ( received_in[121] ^ expected_in[121] );
     compare_z[122] = ( received_in[122] ^ expected_in[122] );
     compare_z[123] = ( received_in[123] ^ expected_in[123] );
     compare_z[124] = ( received_in[124] ^ expected_in[124] );
     compare_z[125] = ( received_in[125] ^ expected_in[125] );
     compare_z[126] = ( received_in[126] ^ expected_in[126] );
     compare_z[127] = ( received_in[127] ^ expected_in[127] );
     compare_z[128] = ( received_in[128] ^ expected_in[128] );
     compare_z[129] = ( received_in[129] ^ expected_in[129] );
     compare_z[130] = ( received_in[130] ^ expected_in[130] );
     compare_z[131] = ( received_in[131] ^ expected_in[131] );
     compare_z[132] = ( received_in[132] ^ expected_in[132] );
     compare_z[133] = ( received_in[133] ^ expected_in[133] );
     compare_z[134] = ( received_in[134] ^ expected_in[134] );
     compare_z[135] = ( received_in[135] ^ expected_in[135] );
     compare_z[136] = ( received_in[136] ^ expected_in[136] );
     compare_z[137] = ( received_in[137] ^ expected_in[137] );
     compare_z[138] = ( received_in[138] ^ expected_in[138] );
     compare_z[139] = ( received_in[139] ^ expected_in[139] );
     compare_z[140] = ( received_in[140] ^ expected_in[140] );
     compare_z[141] = ( received_in[141] ^ expected_in[141] );
     compare_z[142] = ( received_in[142] ^ expected_in[142] );
     compare_z[143] = ( received_in[143] ^ expected_in[143] );
     compare_z[144] = ( received_in[144] ^ expected_in[144] );
     compare_z[145] = ( received_in[145] ^ expected_in[145] );
     compare_z[146] = ( received_in[146] ^ expected_in[146] );
     compare_z[147] = ( received_in[147] ^ expected_in[147] );
     compare_z[148] = ( received_in[148] ^ expected_in[148] );
     compare_z[149] = ( received_in[149] ^ expected_in[149] );
     compare_z[150] = ( received_in[150] ^ expected_in[150] );
     compare_z[151] = ( received_in[151] ^ expected_in[151] );
     compare_z[152] = ( received_in[152] ^ expected_in[152] );
     compare_z[153] = ( received_in[153] ^ expected_in[153] );
     compare_z[154] = ( received_in[154] ^ expected_in[154] );
     compare_z[155] = ( received_in[155] ^ expected_in[155] );
     compare_z[156] = ( received_in[156] ^ expected_in[156] );
     compare_z[157] = ( received_in[157] ^ expected_in[157] );
     compare_z[158] = ( received_in[158] ^ expected_in[158] );
     compare_z[159] = ( received_in[159] ^ expected_in[159] );
     compare_z[160] = ( received_in[160] ^ expected_in[160] );
     compare_z[161] = ( received_in[161] ^ expected_in[161] );
     compare_z[162] = ( received_in[162] ^ expected_in[162] );
     compare_z[163] = ( received_in[163] ^ expected_in[163] );
     compare_z[164] = ( received_in[164] ^ expected_in[164] );
     compare_z[165] = ( received_in[165] ^ expected_in[165] );
     compare_z[166] = ( received_in[166] ^ expected_in[166] );
     compare_z[167] = ( received_in[167] ^ expected_in[167] );
     compare_z[168] = ( received_in[168] ^ expected_in[168] );
     compare_z[169] = ( received_in[169] ^ expected_in[169] );
     compare_z[170] = ( received_in[170] ^ expected_in[170] );
     compare_z[171] = ( received_in[171] ^ expected_in[171] );
     compare_z[172] = ( received_in[172] ^ expected_in[172] );
     compare_z[173] = ( received_in[173] ^ expected_in[173] );
     compare_z[174] = ( received_in[174] ^ expected_in[174] );
     compare_z[175] = ( received_in[175] ^ expected_in[175] );
     compare_z[176] = ( received_in[176] ^ expected_in[176] );
     compare_z[177] = ( received_in[177] ^ expected_in[177] );
     compare_z[178] = ( received_in[178] ^ expected_in[178] );
     compare_z[179] = ( received_in[179] ^ expected_in[179] );
     compare_z[180] = ( received_in[180] ^ expected_in[180] );
     compare_z[181] = ( received_in[181] ^ expected_in[181] );
     compare_z[182] = ( received_in[182] ^ expected_in[182] );
     compare_z[183] = ( received_in[183] ^ expected_in[183] );
     compare_z[184] = ( received_in[184] ^ expected_in[184] );
     compare_z[185] = ( received_in[185] ^ expected_in[185] );
     compare_z[186] = ( received_in[186] ^ expected_in[186] );
     compare_z[187] = ( received_in[187] ^ expected_in[187] );
     compare_z[188] = ( received_in[188] ^ expected_in[188] );
     compare_z[189] = ( received_in[189] ^ expected_in[189] );
     compare_z[190] = ( received_in[190] ^ expected_in[190] );
     compare_z[191] = ( received_in[191] ^ expected_in[191] );
     compare_z[192] = ( received_in[192] ^ expected_in[192] );
     compare_z[193] = ( received_in[193] ^ expected_in[193] );
     compare_z[194] = ( received_in[194] ^ expected_in[194] );
     compare_z[195] = ( received_in[195] ^ expected_in[195] );
     compare_z[196] = ( received_in[196] ^ expected_in[196] );
     compare_z[197] = ( received_in[197] ^ expected_in[197] );
     compare_z[198] = ( received_in[198] ^ expected_in[198] );
     compare_z[199] = ( received_in[199] ^ expected_in[199] );
     compare_z[200] = ( received_in[200] ^ expected_in[200] );
     compare_z[201] = ( received_in[201] ^ expected_in[201] );
     compare_z[202] = ( received_in[202] ^ expected_in[202] );
     compare_z[203] = ( received_in[203] ^ expected_in[203] );
     compare_z[204] = ( received_in[204] ^ expected_in[204] );
     compare_z[205] = ( received_in[205] ^ expected_in[205] );
     compare_z[206] = ( received_in[206] ^ expected_in[206] );
     compare_z[207] = ( received_in[207] ^ expected_in[207] );
     compare_z[208] = ( received_in[208] ^ expected_in[208] );
     compare_z[209] = ( received_in[209] ^ expected_in[209] );
     compare_z[210] = ( received_in[210] ^ expected_in[210] );
     compare_z[211] = ( received_in[211] ^ expected_in[211] );
     compare_z[212] = ( received_in[212] ^ expected_in[212] );
     compare_z[213] = ( received_in[213] ^ expected_in[213] );
     compare_z[214] = ( received_in[214] ^ expected_in[214] );
     compare_z[215] = ( received_in[215] ^ expected_in[215] );
     compare_z[216] = ( received_in[216] ^ expected_in[216] );
     compare_z[217] = ( received_in[217] ^ expected_in[217] );
     compare_z[218] = ( received_in[218] ^ expected_in[218] );
     compare_z[219] = ( received_in[219] ^ expected_in[219] );
     compare_z[220] = ( received_in[220] ^ expected_in[220] );
     compare_z[221] = ( received_in[221] ^ expected_in[221] );
     compare_z[222] = ( received_in[222] ^ expected_in[222] );
     compare_z[223] = ( received_in[223] ^ expected_in[223] );
     compare_z[224] = ( received_in[224] ^ expected_in[224] );
     compare_z[225] = ( received_in[225] ^ expected_in[225] );
     compare_z[226] = ( received_in[226] ^ expected_in[226] );
     compare_z[227] = ( received_in[227] ^ expected_in[227] );
     compare_z[228] = ( received_in[228] ^ expected_in[228] );
     compare_z[229] = ( received_in[229] ^ expected_in[229] );
     compare_z[230] = ( received_in[230] ^ expected_in[230] );
     compare_z[231] = ( received_in[231] ^ expected_in[231] );
     compare_z[232] = ( received_in[232] ^ expected_in[232] );
     compare_z[233] = ( received_in[233] ^ expected_in[233] );
     compare_z[234] = ( received_in[234] ^ expected_in[234] );
     compare_z[235] = ( received_in[235] ^ expected_in[235] );
     compare_z[236] = ( received_in[236] ^ expected_in[236] );
     compare_z[237] = ( received_in[237] ^ expected_in[237] );
     compare_z[238] = ( received_in[238] ^ expected_in[238] );
     compare_z[239] = ( received_in[239] ^ expected_in[239] );
     compare_z[240] = ( received_in[240] ^ expected_in[240] );
     compare_z[241] = ( received_in[241] ^ expected_in[241] );
     compare_z[242] = ( received_in[242] ^ expected_in[242] );
     compare_z[243] = ( received_in[243] ^ expected_in[243] );
     compare_z[244] = ( received_in[244] ^ expected_in[244] );
     compare_z[245] = ( received_in[245] ^ expected_in[245] );
     compare_z[246] = ( received_in[246] ^ expected_in[246] );
     compare_z[247] = ( received_in[247] ^ expected_in[247] );
     compare_z[248] = ( received_in[248] ^ expected_in[248] );
     compare_z[249] = ( received_in[249] ^ expected_in[249] );
     compare_z[250] = ( received_in[250] ^ expected_in[250] );
     compare_z[251] = ( received_in[251] ^ expected_in[251] );
     compare_z[252] = ( received_in[252] ^ expected_in[252] );
     compare_z[253] = ( received_in[253] ^ expected_in[253] );
     compare_z[254] = ( received_in[254] ^ expected_in[254] );
     compare_z[255] = ( received_in[255] ^ expected_in[255] );
     compare_z[256] = ( received_in[256] ^ expected_in[256] );
     compare_z[257] = ( received_in[257] ^ expected_in[257] );
     compare_z[258] = ( received_in[258] ^ expected_in[258] );
     compare_z[259] = ( received_in[259] ^ expected_in[259] );
     compare_z[260] = ( received_in[260] ^ expected_in[260] );
     compare_z[261] = ( received_in[261] ^ expected_in[261] );
     compare_z[262] = ( received_in[262] ^ expected_in[262] );
     compare_z[263] = ( received_in[263] ^ expected_in[263] );
     compare_z[264] = ( received_in[264] ^ expected_in[264] );
     compare_z[265] = ( received_in[265] ^ expected_in[265] );
     compare_z[266] = ( received_in[266] ^ expected_in[266] );
     compare_z[267] = ( received_in[267] ^ expected_in[267] );
     compare_z[268] = ( received_in[268] ^ expected_in[268] );
     compare_z[269] = ( received_in[269] ^ expected_in[269] );
     compare_z[270] = ( received_in[270] ^ expected_in[270] );
     compare_z[271] = ( received_in[271] ^ expected_in[271] );
     compare_z[272] = ( received_in[272] ^ expected_in[272] );
     compare_z[273] = ( received_in[273] ^ expected_in[273] );
     compare_z[274] = ( received_in[274] ^ expected_in[274] );
     compare_z[275] = ( received_in[275] ^ expected_in[275] );
     compare_z[276] = ( received_in[276] ^ expected_in[276] );
     compare_z[277] = ( received_in[277] ^ expected_in[277] );
     compare_z[278] = ( received_in[278] ^ expected_in[278] );
     compare_z[279] = ( received_in[279] ^ expected_in[279] );
     compare_z[280] = ( received_in[280] ^ expected_in[280] );
     compare_z[281] = ( received_in[281] ^ expected_in[281] );
     compare_z[282] = ( received_in[282] ^ expected_in[282] );
     compare_z[283] = ( received_in[283] ^ expected_in[283] );
     compare_z[284] = ( received_in[284] ^ expected_in[284] );
     compare_z[285] = ( received_in[285] ^ expected_in[285] );
     compare_z[286] = ( received_in[286] ^ expected_in[286] );
     compare_z[287] = ( received_in[287] ^ expected_in[287] );
     compare_z[288] = ( received_in[288] ^ expected_in[288] );
     compare_z[289] = ( received_in[289] ^ expected_in[289] );
     compare_z[290] = ( received_in[290] ^ expected_in[290] );
     compare_z[291] = ( received_in[291] ^ expected_in[291] );
     compare_z[292] = ( received_in[292] ^ expected_in[292] );
     compare_z[293] = ( received_in[293] ^ expected_in[293] );
     compare_z[294] = ( received_in[294] ^ expected_in[294] );
     compare_z[295] = ( received_in[295] ^ expected_in[295] );
     compare_z[296] = ( received_in[296] ^ expected_in[296] );
     compare_z[297] = ( received_in[297] ^ expected_in[297] );
     compare_z[298] = ( received_in[298] ^ expected_in[298] );
     compare_z[299] = ( received_in[299] ^ expected_in[299] );
     compare_z[300] = ( received_in[300] ^ expected_in[300] );
     compare_z[301] = ( received_in[301] ^ expected_in[301] );
     compare_z[302] = ( received_in[302] ^ expected_in[302] );
     compare_z[303] = ( received_in[303] ^ expected_in[303] );
     compare_z[304] = ( received_in[304] ^ expected_in[304] );
     compare_z[305] = ( received_in[305] ^ expected_in[305] );
     compare_z[306] = ( received_in[306] ^ expected_in[306] );
     compare_z[307] = ( received_in[307] ^ expected_in[307] );
     compare_z[308] = ( received_in[308] ^ expected_in[308] );
     compare_z[309] = ( received_in[309] ^ expected_in[309] );
     compare_z[310] = ( received_in[310] ^ expected_in[310] );
     compare_z[311] = ( received_in[311] ^ expected_in[311] );
     compare_z[312] = ( received_in[312] ^ expected_in[312] );
     compare_z[313] = ( received_in[313] ^ expected_in[313] );
     compare_z[314] = ( received_in[314] ^ expected_in[314] );
     compare_z[315] = ( received_in[315] ^ expected_in[315] );
     compare_z[316] = ( received_in[316] ^ expected_in[316] );
     compare_z[317] = ( received_in[317] ^ expected_in[317] );
     compare_z[318] = ( received_in[318] ^ expected_in[318] );
     compare_z[319] = ( received_in[319] ^ expected_in[319] );
     compare_z[320] = ( received_in[320] ^ expected_in[320] );
     compare_z[321] = ( received_in[321] ^ expected_in[321] );
     compare_z[322] = ( received_in[322] ^ expected_in[322] );
     compare_z[323] = ( received_in[323] ^ expected_in[323] );
     compare_z[324] = ( received_in[324] ^ expected_in[324] );
     compare_z[325] = ( received_in[325] ^ expected_in[325] );
     compare_z[326] = ( received_in[326] ^ expected_in[326] );
     compare_z[327] = ( received_in[327] ^ expected_in[327] );
     compare_z[328] = ( received_in[328] ^ expected_in[328] );
     compare_z[329] = ( received_in[329] ^ expected_in[329] );
     compare_z[330] = ( received_in[330] ^ expected_in[330] );
     compare_z[331] = ( received_in[331] ^ expected_in[331] );
     compare_z[332] = ( received_in[332] ^ expected_in[332] );
     compare_z[333] = ( received_in[333] ^ expected_in[333] );
     compare_z[334] = ( received_in[334] ^ expected_in[334] );
     compare_z[335] = ( received_in[335] ^ expected_in[335] );
     compare_z[336] = ( received_in[336] ^ expected_in[336] );
     compare_z[337] = ( received_in[337] ^ expected_in[337] );
     compare_z[338] = ( received_in[338] ^ expected_in[338] );
     compare_z[339] = ( received_in[339] ^ expected_in[339] );
     compare_z[340] = ( received_in[340] ^ expected_in[340] );
     compare_z[341] = ( received_in[341] ^ expected_in[341] );
     compare_z[342] = ( received_in[342] ^ expected_in[342] );
     compare_z[343] = ( received_in[343] ^ expected_in[343] );
     compare_z[344] = ( received_in[344] ^ expected_in[344] );
     compare_z[345] = ( received_in[345] ^ expected_in[345] );
     compare_z[346] = ( received_in[346] ^ expected_in[346] );
     compare_z[347] = ( received_in[347] ^ expected_in[347] );
     compare_z[348] = ( received_in[348] ^ expected_in[348] );
     compare_z[349] = ( received_in[349] ^ expected_in[349] );
     compare_z[350] = ( received_in[350] ^ expected_in[350] );
     compare_z[351] = ( received_in[351] ^ expected_in[351] );
     compare_z[352] = ( received_in[352] ^ expected_in[352] );
     compare_z[353] = ( received_in[353] ^ expected_in[353] );
     compare_z[354] = ( received_in[354] ^ expected_in[354] );
     compare_z[355] = ( received_in[355] ^ expected_in[355] );
     compare_z[356] = ( received_in[356] ^ expected_in[356] );
     compare_z[357] = ( received_in[357] ^ expected_in[357] );
     compare_z[358] = ( received_in[358] ^ expected_in[358] );
     compare_z[359] = ( received_in[359] ^ expected_in[359] );
     compare_z[360] = ( received_in[360] ^ expected_in[360] );
     compare_z[361] = ( received_in[361] ^ expected_in[361] );
     compare_z[362] = ( received_in[362] ^ expected_in[362] );
     compare_z[363] = ( received_in[363] ^ expected_in[363] );
     compare_z[364] = ( received_in[364] ^ expected_in[364] );
     compare_z[365] = ( received_in[365] ^ expected_in[365] );
     compare_z[366] = ( received_in[366] ^ expected_in[366] );
     compare_z[367] = ( received_in[367] ^ expected_in[367] );
     compare_z[368] = ( received_in[368] ^ expected_in[368] );
     compare_z[369] = ( received_in[369] ^ expected_in[369] );
     compare_z[370] = ( received_in[370] ^ expected_in[370] );
     compare_z[371] = ( received_in[371] ^ expected_in[371] );
     compare_z[372] = ( received_in[372] ^ expected_in[372] );
     compare_z[373] = ( received_in[373] ^ expected_in[373] );
     compare_z[374] = ( received_in[374] ^ expected_in[374] );
     compare_z[375] = ( received_in[375] ^ expected_in[375] );
     compare_z[376] = ( received_in[376] ^ expected_in[376] );
     compare_z[377] = ( received_in[377] ^ expected_in[377] );
     compare_z[378] = ( received_in[378] ^ expected_in[378] );
     compare_z[379] = ( received_in[379] ^ expected_in[379] );
     compare_z[380] = ( received_in[380] ^ expected_in[380] );
     compare_z[381] = ( received_in[381] ^ expected_in[381] );
     compare_z[382] = ( received_in[382] ^ expected_in[382] );
     compare_z[383] = ( received_in[383] ^ expected_in[383] );
     compare_z[384] = ( received_in[384] ^ expected_in[384] );
     compare_z[385] = ( received_in[385] ^ expected_in[385] );
     compare_z[386] = ( received_in[386] ^ expected_in[386] );
     compare_z[387] = ( received_in[387] ^ expected_in[387] );
     compare_z[388] = ( received_in[388] ^ expected_in[388] );
     compare_z[389] = ( received_in[389] ^ expected_in[389] );
     compare_z[390] = ( received_in[390] ^ expected_in[390] );
     compare_z[391] = ( received_in[391] ^ expected_in[391] );
     compare_z[392] = ( received_in[392] ^ expected_in[392] );
     compare_z[393] = ( received_in[393] ^ expected_in[393] );
     compare_z[394] = ( received_in[394] ^ expected_in[394] );
     compare_z[395] = ( received_in[395] ^ expected_in[395] );
     compare_z[396] = ( received_in[396] ^ expected_in[396] );
     compare_z[397] = ( received_in[397] ^ expected_in[397] );
     compare_z[398] = ( received_in[398] ^ expected_in[398] );
     compare_z[399] = ( received_in[399] ^ expected_in[399] );
     compare_z[400] = ( received_in[400] ^ expected_in[400] );
     compare_z[401] = ( received_in[401] ^ expected_in[401] );
     compare_z[402] = ( received_in[402] ^ expected_in[402] );
     compare_z[403] = ( received_in[403] ^ expected_in[403] );
     compare_z[404] = ( received_in[404] ^ expected_in[404] );
     compare_z[405] = ( received_in[405] ^ expected_in[405] );
     compare_z[406] = ( received_in[406] ^ expected_in[406] );
     compare_z[407] = ( received_in[407] ^ expected_in[407] );
     compare_z[408] = ( received_in[408] ^ expected_in[408] );
     compare_z[409] = ( received_in[409] ^ expected_in[409] );
     compare_z[410] = ( received_in[410] ^ expected_in[410] );
     compare_z[411] = ( received_in[411] ^ expected_in[411] );
     compare_z[412] = ( received_in[412] ^ expected_in[412] );
     compare_z[413] = ( received_in[413] ^ expected_in[413] );
     compare_z[414] = ( received_in[414] ^ expected_in[414] );
     compare_z[415] = ( received_in[415] ^ expected_in[415] );
     compare_z[416] = ( received_in[416] ^ expected_in[416] );
     compare_z[417] = ( received_in[417] ^ expected_in[417] );
     compare_z[418] = ( received_in[418] ^ expected_in[418] );
     compare_z[419] = ( received_in[419] ^ expected_in[419] );
     compare_z[420] = ( received_in[420] ^ expected_in[420] );
     compare_z[421] = ( received_in[421] ^ expected_in[421] );
     compare_z[422] = ( received_in[422] ^ expected_in[422] );
     compare_z[423] = ( received_in[423] ^ expected_in[423] );
     compare_z[424] = ( received_in[424] ^ expected_in[424] );
     compare_z[425] = ( received_in[425] ^ expected_in[425] );
     compare_z[426] = ( received_in[426] ^ expected_in[426] );
     compare_z[427] = ( received_in[427] ^ expected_in[427] );
     compare_z[428] = ( received_in[428] ^ expected_in[428] );
     compare_z[429] = ( received_in[429] ^ expected_in[429] );
     compare_z[430] = ( received_in[430] ^ expected_in[430] );
     compare_z[431] = ( received_in[431] ^ expected_in[431] );
     compare_z[432] = ( received_in[432] ^ expected_in[432] );
     compare_z[433] = ( received_in[433] ^ expected_in[433] );
     compare_z[434] = ( received_in[434] ^ expected_in[434] );
     compare_z[435] = ( received_in[435] ^ expected_in[435] );
     compare_z[436] = ( received_in[436] ^ expected_in[436] );
     compare_z[437] = ( received_in[437] ^ expected_in[437] );
     compare_z[438] = ( received_in[438] ^ expected_in[438] );
     compare_z[439] = ( received_in[439] ^ expected_in[439] );
     compare_z[440] = ( received_in[440] ^ expected_in[440] );
     compare_z[441] = ( received_in[441] ^ expected_in[441] );
     compare_z[442] = ( received_in[442] ^ expected_in[442] );
     compare_z[443] = ( received_in[443] ^ expected_in[443] );
     compare_z[444] = ( received_in[444] ^ expected_in[444] );
     compare_z[445] = ( received_in[445] ^ expected_in[445] );
     compare_z[446] = ( received_in[446] ^ expected_in[446] );
     compare_z[447] = ( received_in[447] ^ expected_in[447] );
     compare_z[448] = ( received_in[448] ^ expected_in[448] );
     compare_z[449] = ( received_in[449] ^ expected_in[449] );
     compare_z[450] = ( received_in[450] ^ expected_in[450] );
     compare_z[451] = ( received_in[451] ^ expected_in[451] );
     compare_z[452] = ( received_in[452] ^ expected_in[452] );
     compare_z[453] = ( received_in[453] ^ expected_in[453] );
     compare_z[454] = ( received_in[454] ^ expected_in[454] );
     compare_z[455] = ( received_in[455] ^ expected_in[455] );
     compare_z[456] = ( received_in[456] ^ expected_in[456] );
     compare_z[457] = ( received_in[457] ^ expected_in[457] );
     compare_z[458] = ( received_in[458] ^ expected_in[458] );
     compare_z[459] = ( received_in[459] ^ expected_in[459] );
     compare_z[460] = ( received_in[460] ^ expected_in[460] );
     compare_z[461] = ( received_in[461] ^ expected_in[461] );
     compare_z[462] = ( received_in[462] ^ expected_in[462] );
     compare_z[463] = ( received_in[463] ^ expected_in[463] );
     compare_z[464] = ( received_in[464] ^ expected_in[464] );
     compare_z[465] = ( received_in[465] ^ expected_in[465] );
     compare_z[466] = ( received_in[466] ^ expected_in[466] );
     compare_z[467] = ( received_in[467] ^ expected_in[467] );
     compare_z[468] = ( received_in[468] ^ expected_in[468] );
     compare_z[469] = ( received_in[469] ^ expected_in[469] );
     compare_z[470] = ( received_in[470] ^ expected_in[470] );
     compare_z[471] = ( received_in[471] ^ expected_in[471] );
     compare_z[472] = ( received_in[472] ^ expected_in[472] );
     compare_z[473] = ( received_in[473] ^ expected_in[473] );
     compare_z[474] = ( received_in[474] ^ expected_in[474] );
     compare_z[475] = ( received_in[475] ^ expected_in[475] );
     compare_z[476] = ( received_in[476] ^ expected_in[476] );
     compare_z[477] = ( received_in[477] ^ expected_in[477] );
     compare_z[478] = ( received_in[478] ^ expected_in[478] );
     compare_z[479] = ( received_in[479] ^ expected_in[479] );
     compare_z[480] = ( received_in[480] ^ expected_in[480] );
     compare_z[481] = ( received_in[481] ^ expected_in[481] );
     compare_z[482] = ( received_in[482] ^ expected_in[482] );
     compare_z[483] = ( received_in[483] ^ expected_in[483] );
     compare_z[484] = ( received_in[484] ^ expected_in[484] );
     compare_z[485] = ( received_in[485] ^ expected_in[485] );
     compare_z[486] = ( received_in[486] ^ expected_in[486] );
     compare_z[487] = ( received_in[487] ^ expected_in[487] );
     compare_z[488] = ( received_in[488] ^ expected_in[488] );
     compare_z[489] = ( received_in[489] ^ expected_in[489] );
     compare_z[490] = ( received_in[490] ^ expected_in[490] );
     compare_z[491] = ( received_in[491] ^ expected_in[491] );
     compare_z[492] = ( received_in[492] ^ expected_in[492] );
     compare_z[493] = ( received_in[493] ^ expected_in[493] );
     compare_z[494] = ( received_in[494] ^ expected_in[494] );
     compare_z[495] = ( received_in[495] ^ expected_in[495] );
     compare_z[496] = ( received_in[496] ^ expected_in[496] );
     compare_z[497] = ( received_in[497] ^ expected_in[497] );
     compare_z[498] = ( received_in[498] ^ expected_in[498] );
     compare_z[499] = ( received_in[499] ^ expected_in[499] );
     compare_z[500] = ( received_in[500] ^ expected_in[500] );
     compare_z[501] = ( received_in[501] ^ expected_in[501] );
     compare_z[502] = ( received_in[502] ^ expected_in[502] );
     compare_z[503] = ( received_in[503] ^ expected_in[503] );
     compare_z[504] = ( received_in[504] ^ expected_in[504] );
     compare_z[505] = ( received_in[505] ^ expected_in[505] );
     compare_z[506] = ( received_in[506] ^ expected_in[506] );
     compare_z[507] = ( received_in[507] ^ expected_in[507] );
     compare_z[508] = ( received_in[508] ^ expected_in[508] );
     compare_z[509] = ( received_in[509] ^ expected_in[509] );
     compare_z[510] = ( received_in[510] ^ expected_in[510] );
     compare_z[511] = ( received_in[511] ^ expected_in[511] );
end

always_comb
begin
     compare_out[0] = ( |compare_z[7:0] ) & byte_mask_reg_in[0];
     compare_out[1] = ( |compare_z[15:8] ) & byte_mask_reg_in[1];
     compare_out[2] = ( |compare_z[23:16] ) & byte_mask_reg_in[2];
     compare_out[3] = ( |compare_z[31:24] ) & byte_mask_reg_in[3];
     compare_out[4] = ( |compare_z[39:32] ) & byte_mask_reg_in[4];
     compare_out[5] = ( |compare_z[47:40] ) & byte_mask_reg_in[5];
     compare_out[6] = ( |compare_z[55:48] ) & byte_mask_reg_in[6];
     compare_out[7] = ( |compare_z[63:56] ) & byte_mask_reg_in[7];
     compare_out[8] = ( |compare_z[71:64] ) & byte_mask_reg_in[8];
     compare_out[9] = ( |compare_z[79:72] ) & byte_mask_reg_in[9];
     compare_out[10] = ( |compare_z[87:80] ) & byte_mask_reg_in[10];
     compare_out[11] = ( |compare_z[95:88] ) & byte_mask_reg_in[11];
     compare_out[12] = ( |compare_z[103:96] ) & byte_mask_reg_in[12];
     compare_out[13] = ( |compare_z[111:104] ) & byte_mask_reg_in[13];
     compare_out[14] = ( |compare_z[119:112] ) & byte_mask_reg_in[14];
     compare_out[15] = ( |compare_z[127:120] ) & byte_mask_reg_in[15];
     compare_out[16] = ( |compare_z[135:128] ) & byte_mask_reg_in[16];
     compare_out[17] = ( |compare_z[143:136] ) & byte_mask_reg_in[17];
     compare_out[18] = ( |compare_z[151:144] ) & byte_mask_reg_in[18];
     compare_out[19] = ( |compare_z[159:152] ) & byte_mask_reg_in[19];
     compare_out[20] = ( |compare_z[167:160] ) & byte_mask_reg_in[20];
     compare_out[21] = ( |compare_z[175:168] ) & byte_mask_reg_in[21];
     compare_out[22] = ( |compare_z[183:176] ) & byte_mask_reg_in[22];
     compare_out[23] = ( |compare_z[191:184] ) & byte_mask_reg_in[23];
     compare_out[24] = ( |compare_z[199:192] ) & byte_mask_reg_in[24];
     compare_out[25] = ( |compare_z[207:200] ) & byte_mask_reg_in[25];
     compare_out[26] = ( |compare_z[215:208] ) & byte_mask_reg_in[26];
     compare_out[27] = ( |compare_z[223:216] ) & byte_mask_reg_in[27];
     compare_out[28] = ( |compare_z[231:224] ) & byte_mask_reg_in[28];
     compare_out[29] = ( |compare_z[239:232] ) & byte_mask_reg_in[29];
     compare_out[30] = ( |compare_z[247:240] ) & byte_mask_reg_in[30];
     compare_out[31] = ( |compare_z[255:248] ) & byte_mask_reg_in[31];
     compare_out[32] = ( |compare_z[263:256] ) & byte_mask_reg_in[32];
     compare_out[33] = ( |compare_z[271:264] ) & byte_mask_reg_in[33];
     compare_out[34] = ( |compare_z[279:272] ) & byte_mask_reg_in[34];
     compare_out[35] = ( |compare_z[287:280] ) & byte_mask_reg_in[35];
     compare_out[36] = ( |compare_z[295:288] ) & byte_mask_reg_in[36];
     compare_out[37] = ( |compare_z[303:296] ) & byte_mask_reg_in[37];
     compare_out[38] = ( |compare_z[311:304] ) & byte_mask_reg_in[38];
     compare_out[39] = ( |compare_z[319:312] ) & byte_mask_reg_in[39];
     compare_out[40] = ( |compare_z[327:320] ) & byte_mask_reg_in[40];
     compare_out[41] = ( |compare_z[335:328] ) & byte_mask_reg_in[41];
     compare_out[42] = ( |compare_z[343:336] ) & byte_mask_reg_in[42];
     compare_out[43] = ( |compare_z[351:344] ) & byte_mask_reg_in[43];
     compare_out[44] = ( |compare_z[359:352] ) & byte_mask_reg_in[44];
     compare_out[45] = ( |compare_z[367:360] ) & byte_mask_reg_in[45];
     compare_out[46] = ( |compare_z[375:368] ) & byte_mask_reg_in[46];
     compare_out[47] = ( |compare_z[383:376] ) & byte_mask_reg_in[47];
     compare_out[48] = ( |compare_z[391:384] ) & byte_mask_reg_in[48];
     compare_out[49] = ( |compare_z[399:392] ) & byte_mask_reg_in[49];
     compare_out[50] = ( |compare_z[407:400] ) & byte_mask_reg_in[50];
     compare_out[51] = ( |compare_z[415:408] ) & byte_mask_reg_in[51];
     compare_out[52] = ( |compare_z[423:416] ) & byte_mask_reg_in[52];
     compare_out[53] = ( |compare_z[431:424] ) & byte_mask_reg_in[53];
     compare_out[54] = ( |compare_z[439:432] ) & byte_mask_reg_in[54];
     compare_out[55] = ( |compare_z[447:440] ) & byte_mask_reg_in[55];
     compare_out[56] = ( |compare_z[455:448] ) & byte_mask_reg_in[56];
     compare_out[57] = ( |compare_z[463:456] ) & byte_mask_reg_in[57];
     compare_out[58] = ( |compare_z[471:464] ) & byte_mask_reg_in[58];
     compare_out[59] = ( |compare_z[479:472] ) & byte_mask_reg_in[59];
     compare_out[60] = ( |compare_z[487:480] ) & byte_mask_reg_in[60];
     compare_out[61] = ( |compare_z[495:488] ) & byte_mask_reg_in[61];
     compare_out[62] = ( |compare_z[503:496] ) & byte_mask_reg_in[62];
     compare_out[63] = ( |compare_z[511:504] ) & byte_mask_reg_in[63];
end

endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "ePCZXRcQZxVjgFf3d0fa7Xtvp3Z7qOlYsAIeuX+MspnMT4Ik9NOFrJx7/YVtfHEK37J+shEoLcx9nOJrvxdKmJOx6Ux1xITFwzBvWI8UB/N89lDxsJWAJPPh9qaSixMk7nzgCQr66xlLogyC4GYXJIJRnXRGSM5tSuyPD/s2hOQukb8JThjWKuuRKX0Ayo2zids8tKadV4M712y6dJQcLhr1UGdk65LSS/9cZMx+tcfrgeFc5PMrn/22S7O4+JydA50/yXA08ZClOxYji+uk+jdytoejIQXSJ9AdGgsy7NXfMj5K9DF+znVkE8ht0vnlg+thebEgDdsbl+dJ0TYB/9Pth3B3BJdzVHGr6Yifx8PRKzCbn8Rh37tTdI4mFnSKZsDzpK7EXBT3oodGQWdp5mKgf61D6D5uGKwEouJ6BkAGnwzl9F4KG2U4t1LHgpgbPawpI7FSg08nc8eUSS4TuRLaHDqst/JtKa5AXNLfH4KovbHuZrZJxQaEiG0kh7qOlp7V1JvYWMbL1r/+RHcBfLOvzUCDcI15xdVE/WCx9Q27xBaH8HB2W/vTOyzYnQQre8GbQrZBiw1TdQINq/wndvlb+iE+zMh2Fv6ZKd4PH0gWLP3MpwLdS59Ngyp4zcg3L2RJzYbpjRngVs6sNBfkgaKeMYaqNMcUiFiSS43m8JvYtvmuRALcYcDnAsnnHs7ZFq6i2sKeC2KaQqLQBqYou39vr22XAQcyRiW4J1+lcLoTpsZhTDiP6sMMucQFfTDerfC8IbNUnZ0452YjhJ0GZHRsjbnUXCcUxXKAcrW+nQIeFiJtseGrjDq+BcWaB1ISJehzqvXDrScisY/eaVjiV7HSK4H7bw5V8boYBlhvsqv2GPOBwOdBJnCLNL8LBOJPlxGBs68qGWUcfpsFUm4oW+LS6eTSW2UQ8vVhe1XqjlxMhsWQOl0tNhi7n1dxSdsVkt5ika8+l0/tHz5MwLxGZFAtHLgOq1FeGVO1xv2+eoNfhxDOA0XusW5uBsIZKdmH"
`endif