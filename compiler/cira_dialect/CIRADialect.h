//===- CIRADialect.h - CIRA dialect declaration -----------------*- C++ -*-===//
#ifndef CIRA_DIALECT_H
#define CIRA_DIALECT_H

#include "mlir/IR/Dialect.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

// Include tablegen-generated dialect declaration
#include "CIRADialect.h.inc"

#endif // CIRA_DIALECT_H
