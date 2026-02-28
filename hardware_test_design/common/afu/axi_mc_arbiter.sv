// AXI MC Arbiter: 2-master-to-1-slave AXI4 arbiter for MC Channel 1
//
// Port 0 (m0): Host HDM Channel 1 traffic from CXL IP (8-bit ID)
// Port 1 (m1): GPU Port1 traffic from Vortex wrapper (4-bit ID)
// Slave:        MC Channel 1 (8-bit ID)
//
// ID tagging: m0 ID[7]=0, ID[6:0]=host_id[6:0]; m1 ID[7]=1, ID[6:0]={3'b0,gpu_id[3:0]}
// Response routing: bid/rid[7] selects master

module axi_mc_arbiter #(
    parameter ID_WIDTH   = 8,
    parameter ADDR_WIDTH = 52,
    parameter DATA_WIDTH = 512,
    parameter LEN_WIDTH  = 10,
    parameter GPU_ID_W   = 4
)(
    input  logic clk,
    input  logic rst_n,

    // ---- Master 0 (Host HDM Ch1) ----
    // AW
    input  logic                  m0_awvalid,
    output logic                  m0_awready,
    input  logic [ID_WIDTH-1:0]   m0_awid,
    input  logic [ADDR_WIDTH-1:0] m0_awaddr,
    input  logic [LEN_WIDTH-1:0]  m0_awlen,
    input  logic [2:0]            m0_awsize,
    input  logic [1:0]            m0_awburst,
    input  logic [3:0]            m0_awcache,
    input  logic [2:0]            m0_awprot,
    input  logic [3:0]            m0_awqos,
    input  logic [3:0]            m0_awregion,
    input  logic                  m0_awuser,
    input  logic [1:0]            m0_awlock,
    // W
    input  logic                  m0_wvalid,
    output logic                  m0_wready,
    input  logic [DATA_WIDTH-1:0] m0_wdata,
    input  logic [DATA_WIDTH/8-1:0] m0_wstrb,
    input  logic                  m0_wlast,
    input  logic                  m0_wuser,
    // B
    output logic                  m0_bvalid,
    input  logic                  m0_bready,
    output logic [ID_WIDTH-1:0]   m0_bid,
    output logic [1:0]            m0_bresp,
    output logic                  m0_buser,
    // AR
    input  logic                  m0_arvalid,
    output logic                  m0_arready,
    input  logic [ID_WIDTH-1:0]   m0_arid,
    input  logic [ADDR_WIDTH-1:0] m0_araddr,
    input  logic [LEN_WIDTH-1:0]  m0_arlen,
    input  logic [2:0]            m0_arsize,
    input  logic [1:0]            m0_arburst,
    input  logic [3:0]            m0_arcache,
    input  logic [2:0]            m0_arprot,
    input  logic [3:0]            m0_arqos,
    input  logic [3:0]            m0_arregion,
    input  logic                  m0_aruser,
    input  logic [1:0]            m0_arlock,
    // R
    output logic                  m0_rvalid,
    input  logic                  m0_rready,
    output logic [ID_WIDTH-1:0]   m0_rid,
    output logic [DATA_WIDTH-1:0] m0_rdata,
    output logic [1:0]            m0_rresp,
    output logic                  m0_rlast,
    output logic                  m0_ruser,

    // ---- Master 1 (GPU Port1) ----
    // AW
    input  logic                  m1_awvalid,
    output logic                  m1_awready,
    input  logic [GPU_ID_W-1:0]   m1_awid,
    input  logic [63:0]           m1_awaddr,
    input  logic [7:0]            m1_awlen,
    input  logic [2:0]            m1_awsize,
    input  logic [1:0]            m1_awburst,
    input  logic [3:0]            m1_awcache,
    input  logic [2:0]            m1_awprot,
    input  logic                  m1_awlock,
    // W
    input  logic                  m1_wvalid,
    output logic                  m1_wready,
    input  logic [DATA_WIDTH-1:0] m1_wdata,
    input  logic [DATA_WIDTH/8-1:0] m1_wstrb,
    input  logic                  m1_wlast,
    // B
    output logic                  m1_bvalid,
    input  logic                  m1_bready,
    output logic [GPU_ID_W-1:0]   m1_bid,
    output logic [1:0]            m1_bresp,
    // AR
    input  logic                  m1_arvalid,
    output logic                  m1_arready,
    input  logic [GPU_ID_W-1:0]   m1_arid,
    input  logic [63:0]           m1_araddr,
    input  logic [7:0]            m1_arlen,
    input  logic [2:0]            m1_arsize,
    input  logic [1:0]            m1_arburst,
    input  logic [3:0]            m1_arcache,
    input  logic [2:0]            m1_arprot,
    input  logic                  m1_arlock,
    // R
    output logic                  m1_rvalid,
    input  logic                  m1_rready,
    output logic [GPU_ID_W-1:0]   m1_rid,
    output logic [DATA_WIDTH-1:0] m1_rdata,
    output logic [1:0]            m1_rresp,
    output logic                  m1_rlast,

    // ---- Slave (MC Channel 1) ----
    // AW
    output logic                  s_awvalid,
    input  logic                  s_awready,
    output logic [ID_WIDTH-1:0]   s_awid,
    output logic [ADDR_WIDTH-1:0] s_awaddr,
    output logic [LEN_WIDTH-1:0]  s_awlen,
    output logic [2:0]            s_awsize,
    output logic [1:0]            s_awburst,
    output logic [3:0]            s_awcache,
    output logic [2:0]            s_awprot,
    output logic [3:0]            s_awqos,
    output logic [3:0]            s_awregion,
    output logic                  s_awuser,
    output logic [1:0]            s_awlock,
    // W
    output logic                  s_wvalid,
    input  logic                  s_wready,
    output logic [DATA_WIDTH-1:0] s_wdata,
    output logic [DATA_WIDTH/8-1:0] s_wstrb,
    output logic                  s_wlast,
    output logic                  s_wuser,
    // B
    input  logic                  s_bvalid,
    output logic                  s_bready,
    input  logic [ID_WIDTH-1:0]   s_bid,
    input  logic [1:0]            s_bresp,
    input  logic                  s_buser,
    // AR
    output logic                  s_arvalid,
    input  logic                  s_arready,
    output logic [ID_WIDTH-1:0]   s_arid,
    output logic [ADDR_WIDTH-1:0] s_araddr,
    output logic [LEN_WIDTH-1:0]  s_arlen,
    output logic [2:0]            s_arsize,
    output logic [1:0]            s_arburst,
    output logic [3:0]            s_arcache,
    output logic [2:0]            s_arprot,
    output logic [3:0]            s_arqos,
    output logic [3:0]            s_arregion,
    output logic                  s_aruser,
    output logic [1:0]            s_arlock,
    // R
    input  logic                  s_rvalid,
    output logic                  s_rready,
    input  logic [ID_WIDTH-1:0]   s_rid,
    input  logic [DATA_WIDTH-1:0] s_rdata,
    input  logic [1:0]            s_rresp,
    input  logic                  s_rlast,
    input  logic                  s_ruser
);

    // =====================================================================
    // Write Address Channel Arbiter (round-robin)
    // =====================================================================
    logic aw_grant;  // 0=m0, 1=m1
    logic aw_last_grant;
    logic aw_locked; // locked while W beats in flight

    // Track pending W beats: after AW grant, W channel is locked to that master
    // until wlast is seen
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_last_grant <= 1'b0;
            aw_locked     <= 1'b0;
            aw_grant      <= 1'b0;
        end else begin
            if (aw_locked) begin
                // Wait for W transfer with wlast
                if (s_wvalid && s_wready && s_wlast)
                    aw_locked <= 1'b0;
            end else if (s_awvalid && s_awready) begin
                // AW handshake occurred, lock W channel
                aw_locked     <= 1'b1;
                aw_last_grant <= aw_grant;
            end

            // Compute next grant (round-robin)
            if (!aw_locked && !(s_awvalid && s_awready)) begin
                // Round-robin: prefer the one that didn't go last
                if (m0_awvalid && m1_awvalid)
                    aw_grant <= aw_last_grant ? 1'b0 : 1'b1;  // toggle
                else if (m0_awvalid)
                    aw_grant <= 1'b0;
                else if (m1_awvalid)
                    aw_grant <= 1'b1;
            end
        end
    end

    // AW mux
    always_comb begin
        if (!aw_locked && ((aw_grant == 1'b0 && m0_awvalid) || (aw_grant == 1'b1 && m1_awvalid))) begin
            s_awvalid = 1'b1;
        end else begin
            s_awvalid = 1'b0;
        end

        if (aw_grant == 1'b0) begin
            // Host (m0)
            s_awid     = {1'b0, m0_awid[6:0]};
            s_awaddr   = m0_awaddr;
            s_awlen    = m0_awlen;
            s_awsize   = m0_awsize;
            s_awburst  = m0_awburst;
            s_awcache  = m0_awcache;
            s_awprot   = m0_awprot;
            s_awqos    = m0_awqos;
            s_awregion = m0_awregion;
            s_awuser   = m0_awuser;
            s_awlock   = m0_awlock;
        end else begin
            // GPU (m1)
            s_awid     = {1'b1, 3'b0, m1_awid};
            s_awaddr   = m1_awaddr[ADDR_WIDTH-1:0];
            s_awlen    = {{(LEN_WIDTH-8){1'b0}}, m1_awlen};
            s_awsize   = m1_awsize;
            s_awburst  = m1_awburst;
            s_awcache  = m1_awcache;
            s_awprot   = m1_awprot;
            s_awqos    = 4'h0;
            s_awregion = 4'h0;
            s_awuser   = 1'b1; // target_hdm=1 (device memory)
            s_awlock   = {1'b0, m1_awlock};
        end

        m0_awready = (aw_grant == 1'b0) && !aw_locked && s_awready;
        m1_awready = (aw_grant == 1'b1) && !aw_locked && s_awready;
    end

    // W mux — follows AW grant (locked)
    logic w_grant_r;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            w_grant_r <= 1'b0;
        else if (s_awvalid && s_awready)
            w_grant_r <= aw_grant;
    end

    always_comb begin
        if (aw_locked) begin
            if (w_grant_r == 1'b0) begin
                s_wvalid = m0_wvalid;
                s_wdata  = m0_wdata;
                s_wstrb  = m0_wstrb;
                s_wlast  = m0_wlast;
                s_wuser  = m0_wuser;
                m0_wready = s_wready;
                m1_wready = 1'b0;
            end else begin
                s_wvalid = m1_wvalid;
                s_wdata  = m1_wdata;
                s_wstrb  = m1_wstrb;
                s_wlast  = m1_wlast;
                s_wuser  = 1'b0;
                m0_wready = 1'b0;
                m1_wready = s_wready;
            end
        end else begin
            s_wvalid  = 1'b0;
            s_wdata   = '0;
            s_wstrb   = '0;
            s_wlast   = 1'b0;
            s_wuser   = 1'b0;
            m0_wready = 1'b0;
            m1_wready = 1'b0;
        end
    end

    // =====================================================================
    // Write Response Channel — route by bid[7]
    // =====================================================================
    wire b_to_m1 = s_bid[7];

    assign m0_bvalid = s_bvalid && !b_to_m1;
    assign m0_bid    = {1'b0, s_bid[6:0]};
    assign m0_bresp  = s_bresp;
    assign m0_buser  = s_buser;

    assign m1_bvalid = s_bvalid && b_to_m1;
    assign m1_bid    = s_bid[GPU_ID_W-1:0];
    assign m1_bresp  = s_bresp;

    assign s_bready  = b_to_m1 ? m1_bready : m0_bready;

    // =====================================================================
    // Read Address Channel Arbiter (round-robin, independent from AW)
    // =====================================================================
    logic ar_grant;  // 0=m0, 1=m1
    logic ar_last_grant;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ar_last_grant <= 1'b0;
            ar_grant      <= 1'b0;
        end else begin
            if (s_arvalid && s_arready)
                ar_last_grant <= ar_grant;

            // Compute next grant
            if (!(s_arvalid && s_arready)) begin
                if (m0_arvalid && m1_arvalid)
                    ar_grant <= ar_last_grant ? 1'b0 : 1'b1;
                else if (m0_arvalid)
                    ar_grant <= 1'b0;
                else if (m1_arvalid)
                    ar_grant <= 1'b1;
            end
        end
    end

    // AR mux
    always_comb begin
        if ((ar_grant == 1'b0 && m0_arvalid) || (ar_grant == 1'b1 && m1_arvalid)) begin
            s_arvalid = 1'b1;
        end else begin
            s_arvalid = 1'b0;
        end

        if (ar_grant == 1'b0) begin
            s_arid     = {1'b0, m0_arid[6:0]};
            s_araddr   = m0_araddr;
            s_arlen    = m0_arlen;
            s_arsize   = m0_arsize;
            s_arburst  = m0_arburst;
            s_arcache  = m0_arcache;
            s_arprot   = m0_arprot;
            s_arqos    = m0_arqos;
            s_arregion = m0_arregion;
            s_aruser   = m0_aruser;
            s_arlock   = m0_arlock;
        end else begin
            s_arid     = {1'b1, 3'b0, m1_arid};
            s_araddr   = m1_araddr[ADDR_WIDTH-1:0];
            s_arlen    = {{(LEN_WIDTH-8){1'b0}}, m1_arlen};
            s_arsize   = m1_arsize;
            s_arburst  = m1_arburst;
            s_arcache  = m1_arcache;
            s_arprot   = m1_arprot;
            s_arqos    = 4'h0;
            s_arregion = 4'h0;
            s_aruser   = 1'b1; // target_hdm=1
            s_arlock   = {1'b0, m1_arlock};
        end

        m0_arready = (ar_grant == 1'b0) && s_arready;
        m1_arready = (ar_grant == 1'b1) && s_arready;
    end

    // =====================================================================
    // Read Response Channel — route by rid[7]
    // =====================================================================
    wire r_to_m1 = s_rid[7];

    assign m0_rvalid = s_rvalid && !r_to_m1;
    assign m0_rid    = {1'b0, s_rid[6:0]};
    assign m0_rdata  = s_rdata;
    assign m0_rresp  = s_rresp;
    assign m0_rlast  = s_rlast;
    assign m0_ruser  = s_ruser;

    assign m1_rvalid = s_rvalid && r_to_m1;
    assign m1_rid    = s_rid[GPU_ID_W-1:0];
    assign m1_rdata  = s_rdata;
    assign m1_rresp  = s_rresp;
    assign m1_rlast  = s_rlast;

    assign s_rready  = r_to_m1 ? m1_rready : m0_rready;

endmodule
