//===- CIRAOps.cpp - CIRA operation implementations -------------*- C++ -*-===//

#include "CIRAOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"

using namespace mlir;
using namespace cira;

// Include tablegen-generated type definitions
#define GET_TYPEDEF_CLASSES
#include "CIRATypes.cpp.inc"

// Include tablegen-generated op definitions
#define GET_OP_CLASSES
#include "CIRAOps.cpp.inc"
