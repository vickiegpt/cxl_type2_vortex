//===- CIRAOps.td - CIRA operation definitions -------------*- tablegen -*-===//

#ifndef CIRA_OPS
#define CIRA_OPS

include "mlir/IR/OpBase.td"
include "mlir/IR/FunctionInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "CIRADialect.td"
include "CIRATypes.td"

class CIRA_Op<string mnemonic, list<Trait> traits = []>
    : Op<CIRA_Dialect, mnemonic, traits>;

// =========================================================================
// Memory Operations
// =========================================================================

def CIRA_AllocCxlOp : CIRA_Op<"alloc_cxl"> {
  let summary = "Allocate an LLC tile in CXL memory";
  let description = [{
    Host-side: allocates a cache-line-aligned region in CXL-visible memory.
    Returns a cira.handle pointing to the allocated tile.
  }];
  let results = (outs CIRA_HandleType:$result);
  let assemblyFormat = "attr-dict `:` type($result)";
}

def CIRA_LoadAsyncOp : CIRA_Op<"load_async"> {
  let summary = "Wait for an LLC tile to be filled, then consume";
  let description = [{
    Host-side: blocks until the data at the given handle is available in the
    host LLC (filled by a Vortex prefetch). Uses mwait semantics internally.
  }];
  let arguments = (ins CIRA_HandleType:$handle);
  let assemblyFormat = "$handle attr-dict `:` type($handle)";
}

def CIRA_StoreAsyncOp : CIRA_Op<"store_async"> {
  let summary = "Store a value to CXL memory for device consumption";
  let description = [{
    Host-side: writes val to CXL memory at handle. The device reads
    this value as part of its task arguments.
  }];
  let arguments = (ins CIRA_HandleType:$handle, AnyType:$value);
  let assemblyFormat = "$handle `,` $value attr-dict `:` type($handle) `,` type($value)";
}

def CIRA_FlushOp : CIRA_Op<"flush"> {
  let summary = "Wait for store_async to become globally visible";
  let description = [{
    Host-side: issues clflush and waits for the store at handle to be
    visible to the device. Ensures ordering between host writes and
    device reads.
  }];
  let arguments = (ins CIRA_HandleType:$handle);
  let assemblyFormat = "$handle attr-dict `:` type($handle)";
}

// =========================================================================
// Cache Management Operations (run on Vortex device)
// =========================================================================

def CIRA_InstallCachelineOp : CIRA_Op<"install_cacheline"> {
  let summary = "Device: take ownership of a cacheline";
  let description = [{
    Device-side: uses CXL.cache protocol to bring the cacheline at ptr
    into the Vortex core's local cache in exclusive state.
  }];
  let arguments = (ins CIRA_HandleType:$ptr);
  let assemblyFormat = "$ptr attr-dict `:` type($ptr)";
}

def CIRA_EvictHintOp : CIRA_Op<"evict_hint"> {
  let summary = "Device: hint that a cacheline should be evicted";
  let description = [{
    Device-side: informs the host that cacheline at ptr is no longer
    needed and can be evicted from the LLC to prevent pollution.
  }];
  let arguments = (ins CIRA_HandleType:$ptr);
  let assemblyFormat = "$ptr attr-dict `:` type($ptr)";
}

def CIRA_PrefetchStreamOp : CIRA_Op<"prefetch_stream"> {
  let summary = "Device: execute a prefetch function N times";
  let description = [{
    Device-side: runs the function referenced by symbol N times.
    The function is assumed to be a prefetcher that chases pointers,
    walks arrays, or performs other memory-gathering operations.
  }];
  let arguments = (ins FlatSymbolRefAttr:$func, I64Attr:$count);
  let assemblyFormat = "$func `,` $count attr-dict";
}

def CIRA_PrefetchIndirectOp : CIRA_Op<"prefetch_indirect"> {
  let summary = "Device: prefetch through indirect array access pattern";
  let description = [{
    Device-side: computes ptr[i] = base[index[offset]] for depth steps.
    Used for gather operations where the access pattern is A[B[C[i]]].
  }];
  let arguments = (ins
    CIRA_HandleType:$base,
    CIRA_HandleType:$index_array,
    CIRA_HandleType:$offset_base,
    I64Attr:$depth
  );
  let assemblyFormat = "$base `,` $index_array `,` $offset_base `,` $depth attr-dict `:` type($base)";
}

// =========================================================================
// Synchronization Operations
// =========================================================================

def CIRA_BarrierOp : CIRA_Op<"barrier"> {
  let summary = "Host: wait for all device offload tasks to complete";
  let description = [{
    Host-side: polls completion control bits for all outstanding tasks.
    Each task writes its CompletionData (magic 0xDEADBEEF) to a
    pre-allocated cacheline; the barrier checks all of them.
  }];
  let assemblyFormat = "attr-dict";
}

def CIRA_FutureCreateOp : CIRA_Op<"future_create"> {
  let summary = "Host: allocate cachelines for future signaling";
  let description = [{
    Host-side: allocates num_lines cache-line-aligned slots that the
    device will write completion data into. Returns a future token.
  }];
  let arguments = (ins I64Attr:$num_lines);
  let results = (outs CIRA_FutureType:$result);
  let assemblyFormat = "$num_lines attr-dict `:` type($result)";
}

def CIRA_FutureAwaitOp : CIRA_Op<"future_await"> {
  let summary = "Host: mwait until future is signaled by device";
  let description = [{
    Host-side: uses mwait on the cacheline backing the future.
    If the cacheline is in M/O/E state (device wrote it via DCOH),
    the host proceeds. Otherwise busy-waits in S/I state.
    Does not alter cache state on Granite Rapids (confirmed experimentally).
  }];
  let arguments = (ins CIRA_FutureType:$future);
  let assemblyFormat = "$future attr-dict `:` type($future)";
}

def CIRA_ReleaseOp : CIRA_Op<"release"> {
  let summary = "Host: evict the future's cacheline, signal done";
  let description = [{
    Host-side: evicts the cacheline backing the future, signaling to the
    device that the host has consumed the data and the tile can be reused.
  }];
  let arguments = (ins CIRA_FutureType:$future);
  let assemblyFormat = "$future attr-dict `:` type($future)";
}

// =========================================================================
// Control Operations
// =========================================================================

def CIRA_OffloadOp : CIRA_Op<"offload"> {
  let summary = "Host: create high-priority task and enqueue via MMIO";
  let description = [{
    Host-side: packages a function call with arguments into a task
    descriptor and places it in the MMIO ring buffer queue for the
    Vortex core to execute. High priority tasks preempt low priority.
  }];
  let arguments = (ins
    CIRA_HandleType:$data_ptr,
    FlatSymbolRefAttr:$func,
    Variadic<AnyType>:$args
  );
  let assemblyFormat = "$data_ptr `,` $func `(` $args `)` attr-dict `:` type($data_ptr) `,` type($args)";
}

def CIRA_SpeculateOp : CIRA_Op<"speculate"> {
  let summary = "Host: create low-priority speculative task";
  let description = [{
    Host-side: same as cira.offload but the task has low priority.
    If the Vortex core is busy with high-priority tasks, speculative
    tasks are deferred or dropped. Used for look-ahead prefetching.
  }];
  let arguments = (ins
    CIRA_HandleType:$data_ptr,
    FlatSymbolRefAttr:$func,
    Variadic<AnyType>:$args
  );
  let assemblyFormat = "$data_ptr `,` $func `(` $args `)` attr-dict `:` type($data_ptr) `,` type($args)";
}

def CIRA_PhaseBoundaryOp : CIRA_Op<"phase_boundary"> {
  let summary = "Host: barrier between execution phases";
  let description = [{
    Semantically identical to cira.barrier. Used to demarcate phase
    transitions (e.g., MCF pricing -> price-out) for the scheduler.
    The runtime uses phase boundaries to switch offload strategies
    and trigger ReJIT if the profile has changed.
  }];
  let arguments = (ins OptionalAttr<StrAttr>:$phase_name);
  let assemblyFormat = "($phase_name^)? attr-dict";
}

#endif // CIRA_OPS
