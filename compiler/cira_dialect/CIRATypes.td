//===- CIRATypes.td - CIRA type definitions ----------------*- tablegen -*-===//

#ifndef CIRA_TYPES
#define CIRA_TYPES

include "mlir/IR/OpBase.td"
include "mlir/IR/AttrTypeBase.td"
include "CIRADialect.td"

class CIRA_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<CIRA_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def CIRA_HandleType : CIRA_Type<"Handle", "handle"> {
  let summary = "Pointer guaranteed to reside in CXL memory space";
  let description = [{
    A typed pointer to CXL-resident memory. The host allocates this via
    cira.alloc_cxl and the device can take ownership via cira.install_cacheline.
  }];
  let parameters = (ins "Type":$elementType);
  let assemblyFormat = "`<` $elementType `>`";
}

def CIRA_FutureType : CIRA_Type<"Future", "future"> {
  let summary = "Token representing an in-flight async operation";
  let description = [{
    Created by cira.future_create, consumed by cira.future_await.
    The host uses mwait on the underlying cacheline: if the line is in
    M/O/E state the host proceeds immediately; if S or I the host
    busy-waits until the device writes the completion flag via DCOH.
  }];
  let parameters = (ins "Type":$elementType);
  let assemblyFormat = "`<` $elementType `>`";
}

def CIRA_StreamType : CIRA_Type<"Stream", "stream"> {
  let summary = "Descriptor for a recurring memory access pattern";
  let description = [{
    Encodes a prefetch pattern (stride, indirect, chain) that the Vortex
    core executes repeatedly. Created implicitly by cira.prefetch_stream.
  }];
}

#endif // CIRA_TYPES
