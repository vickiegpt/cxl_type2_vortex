set(LLVM_TARGET_DEFINITIONS CIRAOps.td)
mlir_tablegen(CIRAOps.h.inc -gen-op-decls)
mlir_tablegen(CIRAOps.cpp.inc -gen-op-defs)
mlir_tablegen(CIRADialect.h.inc -gen-dialect-decls)
mlir_tablegen(CIRADialect.cpp.inc -gen-dialect-defs)

set(LLVM_TARGET_DEFINITIONS CIRATypes.td)
mlir_tablegen(CIRATypes.h.inc -gen-typedef-decls)
mlir_tablegen(CIRATypes.cpp.inc -gen-typedef-defs)

add_public_tablegen_target(CIRAIncGen)

add_mlir_dialect_library(CIRADialect
  CIRADialect.cpp
  CIRAOps.cpp

  DEPENDS
  CIRAIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRSupport
)
