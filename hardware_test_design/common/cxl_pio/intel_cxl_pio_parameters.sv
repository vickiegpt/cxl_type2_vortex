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


package intel_cxl_pio_parameters;
    parameter ENABLE_ONLY_DEFAULT_CONFIG= 0;
    parameter ENABLE_ONLY_PIO           = 0;
    parameter ENABLE_BOTH_DEFAULT_CONFIG_PIO = 1;
    parameter PFNUM_WIDTH               = 3;
    parameter VFNUM_WIDTH               = 12;
    parameter DATA_WIDTH                = 1024;
    parameter BAM_DATAWIDTH             = DATA_WIDTH;
    parameter DEVICE_FAMILY             = "Agilex";
    //parameter CXL_IO_DWIDTH = 256; // Data width for each channel
    //parameter CXL_IO_PWIDTH = 32;  // Prefix Width
    //parameter CXL_IO_CHWIDTH = 1;  // Prefix Width

endpackage
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "NpqxALF1IWLnI5+60Lg9xq9HtM2KF+YwkmewwNyDZyswoBvMyCE3S0cdOx7RYs1hNZY1rk+400AKHHRwT8kq0NXV9ZEHV2044KnyJQo/SuNnVHQ4JDhN3MgOvdDoZo9KgcC9Juf4ddZgjs4TEqqEmL7qriJav2KrnFMxkjwWAj4Mx1Hrcjj3prFnkhPNAcQv+oqojCGaqsgphG0TAX5TeG6kAv5EJ7nkboWLlvnSZL6iRp93MsV7ObtK5TzThSfOhn+nYG1xnK0A6a0XhUmFq6bWfo8iyecnEQSy+TBcWplv4bgyg7BgjTmwv6KSWr+TaKpgMTt4r91O4UoVkiIORvwS2uwdfpwnB147XOmkuSMj/Yfoo9jUFPeDedR/1Qc6jGV515jpyytR0K6gVjNORtBBy08LTl6b+OEjRFBJCWp2jeO9akvdPenZvzRI9L8K0stJg9xue3gfcAO8b0S5nYE1P1+sXdoSgSuHZcLOzNITYSbz5Kgt1ELjzfw4h7U+6E7EJLrAWj1/6Lr/7pyBxm9sSoAsKuRJFZsC9CpsIeHXUp+0uNSS846AW59qZVoxXqvIAhUePdgJEFY8HKq3FkjR+2NxpOtVuaSekwRIl3u5PnzGwFcvq36/tqKNyRupCBpWy8uNdseVRlcmAwkCZ6vaBvZV5WnMLYw6y30fc0UtR9RIANGsIHHrr/CpRydOsedO3s2X0n+IrgiQtg2P5EIC8CeHTAeqj9HrB3a77bMwfkvCqtKbebYiALQ+gDEXSeycjEXokBaKxmBFnDZCGPQQ4tji4BTsVfX48DOaFi26Iw/FjM5254ZDwBocuzhKZorgfnWqutSJrcL4RraTuwNcQYLRczEnrkyDbtlLqzXIhZlHiLMGLn2kszoRz5EVwYDg6uBhFJfVLDFH4W/QGOG2S3dSTfGfqnITWVcPVbt0V81j3nXPqrZrajsw6cgx+2gIc1kuBSZAEydtS/btcabkobWoR93m4Etdc2cIoKpRa/XCAmzTWnuX57TrBJJ8"
`endif