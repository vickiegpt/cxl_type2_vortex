//===- CIRADialect.cpp - CIRA dialect registration ----------------*- C++ -*-===//

#include "CIRADialect.h"
#include "CIRAOps.h"

using namespace mlir;
using namespace cira;

// Include tablegen-generated dialect definition
#include "CIRADialect.cpp.inc"

void CIRADialect::initialize() {
  // Register types
  addTypes<
#define GET_TYPEDEF_LIST
#include "CIRATypes.cpp.inc"
  >();
  // Register operations
  addOperations<
#define GET_OP_LIST
#include "CIRAOps.cpp.inc"
  >();
}
