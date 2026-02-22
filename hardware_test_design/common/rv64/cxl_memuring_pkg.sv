// cxl_memuring_pkg.sv
// CXLMemUring Protocol Definitions and Descriptor Formats
//
// This package defines the data structures for CXLMemUring offload engine,
// including submission queue entries (SQE), completion queue entries (CQE),
// opcodes, and control/status registers.

`ifndef CXL_MEMURING_PKG_SV
`define CXL_MEMURING_PKG_SV

package cxl_memuring_pkg;

    // ============================================================================
    // Global Parameters
    // ============================================================================

    parameter int SQE_SIZE_BYTES = 256;          // Submission queue entry size
    parameter int CQE_SIZE_BYTES = 64;           // Completion queue entry size
    parameter int MAX_SQ_ENTRIES = 256;          // Maximum SQ depth
    parameter int MAX_CQ_ENTRIES = 256;          // Maximum CQ depth
    parameter int MAX_OUTSTANDING_OPS = 16;      // Max concurrent operations
    parameter int PREFETCH_DEPTH = 8;            // Speculative prefetch depth

    // Address widths
    parameter int PHYS_ADDR_WIDTH = 52;          // CXL physical address width
    parameter int AXI_ADDR_WIDTH = 64;           // AXI address (zero-extended)
    parameter int AXI_DATA_WIDTH = 512;          // AXI data width (64 bytes)
    parameter int AXI_ID_WIDTH = 12;             // AXI transaction ID width

    // BAR sizes
    parameter longint BAR0_SIZE = 4096;          // CSR space (4KB)
    parameter longint BAR1_SIZE = 65536;         // SQ window (64KB)
    parameter longint BAR2_SIZE = 16384;         // CQ window (16KB)
    parameter longint BAR3_SIZE = 1048576;       // Loader window (1MB)

    // ============================================================================
    // Opcode Definitions
    // ============================================================================

    typedef enum logic [7:0] {
        OPCODE_NOP              = 8'h00,
        OPCODE_LOAD             = 8'h01,
        OPCODE_STORE            = 8'h02,
        OPCODE_RMW_ADD          = 8'h10,
        OPCODE_RMW_CAS          = 8'h11,
        OPCODE_RMW_SWAP         = 8'h12,
        OPCODE_RMW_AND          = 8'h13,
        OPCODE_RMW_OR           = 8'h14,
        OPCODE_RMW_XOR          = 8'h15,
        OPCODE_KERNEL_CALL      = 8'h20,
        OPCODE_BATCH_GATHER     = 8'h30,
        OPCODE_BATCH_SCATTER    = 8'h31,
        OPCODE_STREAM_REDUCE    = 8'h40,
        OPCODE_STREAM_MAP       = 8'h41,
        OPCODE_STREAM_FILTER    = 8'h42,
        OPCODE_ELF_LOAD         = 8'hF0,
        OPCODE_ELF_UNLOAD       = 8'hF1
    } opcode_e;

    // ============================================================================
    // Descriptor Flags
    // ============================================================================

    typedef struct packed {
        logic sync;           // Bit 0: Synchronous completion (block until done)
        logic fence;          // Bit 1: Memory fence before next op
        logic notify;         // Bit 2: Generate interrupt on completion
        logic async;          // Bit 3: Async execution (don't block queue)
        logic prefetch_en;    // Bit 4: Enable speculative prefetch
        logic fault_tolerant; // Bit 5: Continue on fault (best-effort)
        logic [1:0] reserved; // Bits 6-7: Reserved
    } sqe_flags_t;

    // ============================================================================
    // Access Pattern Types
    // ============================================================================

    typedef enum logic [7:0] {
        ACCESS_SEQUENTIAL  = 8'h00,  // A[i], A[i+1], A[i+2], ...
        ACCESS_STRIDED     = 8'h01,  // A[i], A[i+stride], A[i+2*stride], ...
        ACCESS_INDIRECT    = 8'h02,  // A[B[i]], A[B[i+1]], ...
        ACCESS_IRREGULAR   = 8'h03,  // A[B[C[i]]], complex patterns
        ACCESS_RANDOM      = 8'h04   // Random access (no pattern)
    } access_type_e;

    typedef enum logic [7:0] {
        TARGET_AUTO     = 8'h00,     // Automatic routing based on address
        TARGET_HOST     = 8'h01,     // Force route to Host memory (CAFU Port0)
        TARGET_DEVICE   = 8'h02      // Force route to Device memory (CAFU Port1)
    } target_mem_e;

    typedef enum logic [7:0] {
        CACHE_NORMAL        = 8'h00, // Normal LRU caching
        CACHE_STREAM        = 8'h01, // Streaming (bypass L2)
        CACHE_NONTEMPORAL   = 8'h02, // Non-temporal (evict immediately)
        CACHE_PERSISTENT    = 8'h03  // Keep in cache (high priority)
    } cache_hint_e;

    // ============================================================================
    // Condition Operations
    // ============================================================================

    typedef enum logic [7:0] {
        COND_ALWAYS  = 8'h00,  // Always true (no condition)
        COND_LT      = 8'h01,  // <
        COND_LE      = 8'h02,  // <=
        COND_EQ      = 8'h03,  // ==
        COND_NE      = 8'h04,  // !=
        COND_GE      = 8'h05,  // >=
        COND_GT      = 8'h06   // >
    } cond_op_e;

    // ============================================================================
    // Loop Specification
    // ============================================================================

    typedef struct packed {
        logic [31:0] start_idx;   // Loop start index
        logic [31:0] end_idx;     // Loop end index (exclusive)
        logic [31:0] stride;      // Loop stride
    } loop_spec_t;

    // ============================================================================
    // Condition Specification
    // ============================================================================

    typedef struct packed {
        cond_op_e    op;          // Comparison operation
        logic [23:0] reserved;    // Padding
        logic [31:0] threshold;   // Threshold value (float or int)
    } condition_spec_t;

    // ============================================================================
    // Memory Access Pattern
    // ============================================================================

    typedef struct packed {
        // Base addresses (64 bytes)
        logic [63:0] base_ptr;      // A[...] base address
        logic [63:0] index_ptr;     // B[i] index array address
        logic [63:0] cond_base;     // C[...] condition data base
        logic [63:0] cond_index;    // D[j] condition index array

        // Loop specifications (36 bytes)
        loop_spec_t  loop_i;        // Primary loop (i)
        loop_spec_t  loop_j;        // Secondary loop (j)
        loop_spec_t  loop_k;        // Tertiary loop (k)

        // Conditional access (8 bytes)
        condition_spec_t condition;

        // Access pattern metadata (16 bytes)
        logic [31:0] elem_size;     // Element size in bytes
        logic [31:0] elem_count;    // Total elements to process
        access_type_e access_type;  // Access pattern type
        target_mem_e  target_mem;   // Target memory
        cache_hint_e  cache_hint;   // Cache hint
        logic [39:0]  reserved;     // Padding (5 bytes)
    } memory_pattern_t; // Total: 128 bytes

    // ============================================================================
    // DMA Configuration
    // ============================================================================

    typedef struct packed {
        logic [63:0] src_addr;        // Source address
        logic [63:0] dst_addr;        // Destination address
        logic [31:0] length;          // Transfer length in bytes
        logic [31:0] dma_flags;       // DMA control flags
        logic [63:0] completion_addr; // Custom completion address (optional)
        logic [319:0] reserved;       // Padding (40 bytes = 5*64 bits)
    } dma_config_t; // Total: 64 bytes

    // ============================================================================
    // Submission Queue Entry (SQE) - 256 bytes
    // ============================================================================

    typedef struct packed {
        // Header (16 bytes)
        opcode_e      opcode;         // Operation code
        sqe_flags_t   flags;          // Flags
        logic [15:0]  kernel_id;      // Kernel/function ID
        logic [31:0]  sched_priority; // Scheduling priority
        logic [63:0]  user_data;      // User tag (pass-through)

        // Memory access pattern (128 bytes)
        memory_pattern_t pattern;

        // DMA configuration (64 bytes)
        dma_config_t dma_config;

        // Reserved for future extensions (48 bytes)
        logic [383:0] reserved;
    } sqe_t;

    // ============================================================================
    // Completion Queue Entry (CQE) - 64 bytes
    // ============================================================================

    typedef struct packed {
        // Header (16 bytes)
        logic [63:0] user_data;      // From SQE
        logic [31:0] result;         // Status code (0 = success)
        logic [31:0] bytes_xfered;   // Actual bytes transferred

        // Performance counters (32 bytes)
        logic [63:0] cycles_total;   // Total cycles consumed
        logic [63:0] cycles_compute; // Compute cycles
        logic [63:0] cycles_memory;  // Memory stall cycles
        logic [31:0] cache_misses;   // L2 cache misses
        logic [31:0] tlb_misses;     // TLB misses

        // Error information (16 bytes)
        logic [63:0] fault_addr;     // Faulting address (if error)
        logic [31:0] fault_reason;   // Fault type code
        logic [31:0] reserved0;
    } cqe_t;

    // ============================================================================
    // Control/Status Registers (BAR0)
    // ============================================================================

    // CSR offsets (byte addresses)
    localparam logic [11:0] CSR_DEVICE_ID         = 12'h000;
    localparam logic [11:0] CSR_CAPABILITY        = 12'h008;
    localparam logic [11:0] CSR_STATUS            = 12'h010;
    localparam logic [11:0] CSR_CONTROL           = 12'h018;
    localparam logic [11:0] CSR_SQ_BASE           = 12'h020;
    localparam logic [11:0] CSR_SQ_SIZE           = 12'h028;
    localparam logic [11:0] CSR_SQ_HEAD           = 12'h02C;
    localparam logic [11:0] CSR_SQ_TAIL           = 12'h030;
    localparam logic [11:0] CSR_SQ_FLAGS          = 12'h034;
    localparam logic [11:0] CSR_CQ_BASE           = 12'h040;
    localparam logic [11:0] CSR_CQ_SIZE           = 12'h048;
    localparam logic [11:0] CSR_CQ_HEAD           = 12'h04C;
    localparam logic [11:0] CSR_CQ_TAIL           = 12'h050;
    localparam logic [11:0] CSR_CQ_FLAGS          = 12'h054;
    localparam logic [11:0] CSR_DOORBELL          = 12'h060;
    localparam logic [11:0] CSR_INTERRUPT_MASK    = 12'h064;
    localparam logic [11:0] CSR_INTERRUPT_STATUS  = 12'h068;
    localparam logic [11:0] CSR_KERNEL_CFG        = 12'h070;
    localparam logic [11:0] CSR_ELF_LOAD_ADDR     = 12'h080;
    localparam logic [11:0] CSR_ELF_ENTRY_POINT   = 12'h088;
    localparam logic [11:0] CSR_BOOT_STATUS       = 12'h090;
    localparam logic [11:0] CSR_PERF_COUNTER_0    = 12'h100;
    localparam logic [11:0] CSR_PERF_COUNTER_1    = 12'h108;
    localparam logic [11:0] CSR_PERF_COUNTER_2    = 12'h110;
    localparam logic [11:0] CSR_PERF_COUNTER_3    = 12'h118;
    localparam logic [11:0] CSR_FAULT_STATUS      = 12'h200;
    localparam logic [11:0] CSR_FAULT_ADDR        = 12'h208;
    localparam logic [11:0] CSR_FAULT_INFO        = 12'h210;

    // Device ID values
    localparam logic [63:0] DEVICE_ID_VALUE = {
        16'h0001,  // Vendor ID (placeholder)
        16'h1000,  // Device ID
        32'h20241105  // Version: YYYY-MM-DD
    };

    // Capability flags
    typedef struct packed {
        logic has_indirect_access;   // Supports indirect addressing
        logic has_conditional;       // Supports conditional operations
        logic has_nested_loops;      // Supports nested loops
        logic has_prefetch;          // Hardware prefetcher available
        logic has_dma_engine;        // DMA engine present
        logic has_elf_loader;        // ELF loader supported
        logic has_msix;              // MSI-X interrupts supported
        logic has_dual_port;         // Dual-port memory access
        logic [55:0] reserved;
    } capability_t;

    // Device status register
    typedef struct packed {
        logic ready;                 // Device ready for operations
        logic busy;                  // Device busy processing
        logic fault;                 // Fault occurred
        logic sq_full;               // SQ overflow
        logic cq_empty;              // CQ empty
        logic elf_loaded;            // ELF kernel loaded
        logic [57:0] reserved;
    } status_t;

    // Device control register
    typedef struct packed {
        logic enable;                // Enable device
        logic reset;                 // Software reset
        logic boot_trigger;          // Trigger ELF boot sequence
        logic interrupt_enable;      // Enable interrupts
        logic prefetch_enable;       // Enable prefetcher
        logic [58:0] reserved;
    } control_t;

    // Interrupt mask/status
    typedef struct packed {
        logic cq_ready;              // CQ has new entries
        logic sq_full;               // SQ overflow
        logic fault;                 // Fault occurred
        logic perf_overflow;         // Perf counter overflow
        logic [27:0] reserved;
    } interrupt_bits_t;

    // Boot status
    typedef struct packed {
        logic [7:0] boot_stage;      // Boot stage (0=idle, 1=loading, 2=ready)
        logic [23:0] error_code;     // Error code if boot failed
        logic [31:0] reserved;
    } boot_status_t;

    // Fault types
    typedef enum logic [31:0] {
        FAULT_NONE              = 32'h00000000,
        FAULT_PAGE_FAULT        = 32'h00000001,
        FAULT_PROTECTION        = 32'h00000002,
        FAULT_TIMEOUT           = 32'h00000003,
        FAULT_QUEUE_OVERFLOW    = 32'h00000004,
        FAULT_ECC_ERROR         = 32'h00000005,
        FAULT_AXI_DECODE_ERROR  = 32'h00000006,
        FAULT_AXI_SLAVE_ERROR   = 32'h00000007,
        FAULT_ELF_PARSE_ERROR   = 32'h00000010,
        FAULT_ELF_LOAD_ERROR    = 32'h00000011,
        FAULT_INVALID_OPCODE    = 32'h00000020,
        FAULT_INVALID_PATTERN   = 32'h00000021,
        FAULT_DIVISION_BY_ZERO  = 32'h00000030
    } fault_type_e;

    // ============================================================================
    // AXI Interface Extensions (User Signals)
    // ============================================================================

    // AXI ARUSER (Read Address User)
    typedef struct packed {
        logic        target_hdm;          // 1=Device HDM, 0=Host memory
        logic        do_not_send_d2hreq;  // Bypass D2H coherence
        logic [2:0]  opcode;              // CXL.cache opcode
        logic [7:0]  reserved;
    } axi_aruser_t;

    // AXI AWUSER (Write Address User)
    typedef struct packed {
        logic        target_hdm;          // 1=Device HDM, 0=Host memory
        logic        do_not_send_d2hreq;  // Bypass D2H coherence
        logic [2:0]  opcode;              // CXL.cache opcode
        logic [7:0]  reserved;
    } axi_awuser_t;

    // CXL.cache opcodes (Device-to-Host)
    localparam logic [2:0] CXL_RD_CURR      = 3'h0;
    localparam logic [2:0] CXL_RD_OWN       = 3'h1;
    localparam logic [2:0] CXL_RD_SHARED    = 3'h2;
    localparam logic [2:0] CXL_RD_ANY       = 3'h3;
    localparam logic [2:0] CXL_WR_INV       = 3'h0; // Write opcodes
    localparam logic [2:0] CXL_WR_PART_M    = 3'h1;
    localparam logic [2:0] CXL_DIRTY_EVICT  = 3'h4;

    // ============================================================================
    // Helper Functions
    // ============================================================================

    // Calculate number of loop iterations
    function automatic logic [31:0] calc_iterations(loop_spec_t loop);
        if (loop.stride == 0) return 0;
        return (loop.end_idx - loop.start_idx + loop.stride - 1) / loop.stride;
    endfunction

    // Check if address is in Host memory range
    function automatic logic is_host_address(logic [63:0] addr);
        // Convention: addresses >= 0x0001_0000_0000 are Host memory
        return addr[40];
    endfunction

    // Convert cache hint to AXI AxCACHE
    function automatic logic [3:0] cache_hint_to_axi(cache_hint_e hint);
        case (hint)
            CACHE_STREAM:       return 4'b1110; // Modifiable, no allocate
            CACHE_NONTEMPORAL:  return 4'b0000; // Device memory
            CACHE_PERSISTENT:   return 4'b1111; // Writeback, allocate
            default:            return 4'b1111; // Normal
        endcase
    endfunction

    // Convert access type to prefetch distance
    function automatic logic [3:0] access_type_to_prefetch_dist(access_type_e atype);
        case (atype)
            ACCESS_SEQUENTIAL:  return 8;  // Aggressive prefetch
            ACCESS_STRIDED:     return 4;  // Moderate prefetch
            ACCESS_INDIRECT:    return 2;  // Conservative prefetch
            default:            return 0;  // No prefetch
        endcase
    endfunction

    // Calculate total memory footprint of a pattern
    function automatic logic [63:0] calc_memory_footprint(memory_pattern_t pattern);
        logic [63:0] total_iters;
        logic [63:0] footprint;

        total_iters = calc_iterations(pattern.loop_i);
        if (pattern.loop_j.stride != 0)
            total_iters *= calc_iterations(pattern.loop_j);
        if (pattern.loop_k.stride != 0)
            total_iters *= calc_iterations(pattern.loop_k);

        footprint = total_iters * pattern.elem_size;
        return footprint;
    endfunction

    // ============================================================================
    // Checker Functions (for assertions)
    // ============================================================================

    function automatic logic is_valid_sqe(sqe_t sqe);
        // Check basic validity
        if (sqe.opcode == OPCODE_NOP) return 1'b1;

        // Check addresses are aligned
        if (sqe.pattern.base_ptr[2:0] != 0) return 1'b0;

        // Check loop parameters
        if (sqe.pattern.loop_i.start_idx >= sqe.pattern.loop_i.end_idx) return 1'b0;
        if (sqe.pattern.loop_i.stride == 0) return 1'b0;

        return 1'b1;
    endfunction

    function automatic logic is_valid_cqe(cqe_t cqe);
        // CQE is valid if it has been written (non-zero user_data or result)
        return (cqe.user_data != 0) || (cqe.result != 0);
    endfunction

endpackage : cxl_memuring_pkg

`endif // CXL_MEMURING_PKG_SV
