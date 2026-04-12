//===- CIRAOps.h - CIRA operation declarations ------------------*- C++ -*-===//
#ifndef CIRA_OPS_H
#define CIRA_OPS_H

#include "CIRADialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

// Include tablegen-generated type declarations
#define GET_TYPEDEF_CLASSES
#include "CIRATypes.h.inc"

// Include tablegen-generated op declarations
#define GET_OP_CLASSES
#include "CIRAOps.h.inc"

#endif // CIRA_OPS_H
