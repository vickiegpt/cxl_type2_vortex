//===- CIRADialect.td - CIRA dialect definition --------*- tablegen -*-===//
//
// Defines the CIRA (CXL Intermediate Representation for Asynchrony) dialect.
//
//===----------------------------------------------------------------------===//

#ifndef CIRA_DIALECT
#define CIRA_DIALECT

include "mlir/IR/OpBase.td"

def CIRA_Dialect : Dialect {
  let name = "cira";
  let summary = "CXL Intermediate Representation for Asynchrony";
  let description = [{
    The CIRA dialect provides operations for compiler-driven heterogeneous
    execution on CXL Type 2 memory expanders with Vortex RISC-V SIMT cores.
    It captures asynchronous memory access patterns, explicit LLC management,
    and synchronization between x86 host cores and near-memory accelerators.
  }];
  let cppNamespace = "::cira";
  let useDefaultTypePrinterParser = 1;
}

#endif // CIRA_DIALECT
