//===--- CIRGenVTables.h - Emit LLVM Code for C++ vtables -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This contains code dealing with C++ code generation of virtual tables.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_CIR_CODEGEN_CIRGENVTABLES_H
#define LLVM_CLANG_LIB_CIR_CODEGEN_CIRGENVTABLES_H

#include "ConstantInitBuilder.h"
#include "clang/AST/BaseSubobject.h"
#include "clang/AST/CharUnits.h"
#include "clang/AST/GlobalDecl.h"
#include "clang/AST/VTableBuilder.h"
#include "clang/Basic/ABI.h"
#include "llvm/ADT/DenseMap.h"

namespace clang {
class CXXRecordDecl;
}

namespace cir {
class CIRGenModule;
// class ConstantArrayBuilder;
// class ConstantStructBuilder;

class CIRGenVTables {
  CIRGenModule &CGM;

  clang::VTableContextBase *VTContext;

  /// VTableAddressPointsMapTy - Address points for a single vtable.
  typedef clang::VTableLayout::AddressPointsMapTy VTableAddressPointsMapTy;

  typedef std::pair<const clang::CXXRecordDecl *, clang::BaseSubobject>
      BaseSubobjectPairTy;
  typedef llvm::DenseMap<BaseSubobjectPairTy, uint64_t> SubVTTIndiciesMapTy;

  /// SubVTTIndicies - Contains indices into the various sub-VTTs.
  SubVTTIndiciesMapTy SubVTTIndicies;

  typedef llvm::DenseMap<BaseSubobjectPairTy, uint64_t>
      SecondaryVirtualPointerIndicesMapTy;

  /// SecondaryVirtualPointerIndices - Contains the secondary virtual pointer
  /// indices.
  SecondaryVirtualPointerIndicesMapTy SecondaryVirtualPointerIndices;

  //   /// Cache for the pure virtual member call function.
  //   llvm::Constant *PureVirtualFn = nullptr;

  //   /// Cache for the deleted virtual member call function.
  //   llvm::Constant *DeletedVirtualFn = nullptr;

  //   /// Get the address of a thunk and emit it if necessary.
  //   llvm::Constant *maybeEmitThunk(GlobalDecl GD,
  //                                  const ThunkInfo &ThunkAdjustments,
  //                                  bool ForVTable);

  void addVTableComponent(ConstantArrayBuilder &builder,
                          const VTableLayout &layout, unsigned componentIndex,
                          mlir::Attribute rtti, unsigned &nextVTableThunkIndex,
                          unsigned vtableAddressPoint,
                          bool vtableHasLocalLinkage);

  //   /// Add a 32-bit offset to a component relative to the vtable when using
  //   the
  //   /// relative vtables ABI. The array builder points to the start of the
  //   vtable. void addRelativeComponent(ConstantArrayBuilder &builder,
  //                             llvm::Constant *component,
  //                             unsigned vtableAddressPoint,
  //                             bool vtableHasLocalLinkage,
  //                             bool isCompleteDtor) const;

  //   /// Create a dso_local stub that will be used for a relative reference in
  //   the
  //   /// relative vtable layout. This stub will just be a tail call to the
  //   original
  //   /// function and propagate any function attributes from the original. If
  //   the
  //   /// original function is already dso_local, the original is returned
  //   instead
  //   /// and a stub is not created.
  //   llvm::Function *
  //   getOrCreateRelativeStub(llvm::Function *func,
  //                           llvm::GlobalValue::LinkageTypes stubLinkage,
  //                           bool isCompleteDtor) const;

  bool useRelativeLayout() const;

  mlir::Type getVTableComponentType();

public:
  /// Add vtable components for the given vtable layout to the given
  /// global initializer.
  void createVTableInitializer(ConstantStructBuilder &builder,
                               const VTableLayout &layout, mlir::Attribute rtti,
                               bool vtableHasLocalLinkage);

  CIRGenVTables(CIRGenModule &CGM);

  clang::ItaniumVTableContext &getItaniumVTableContext() {
    return *llvm::cast<clang::ItaniumVTableContext>(VTContext);
  }

  const clang::ItaniumVTableContext &getItaniumVTableContext() const {
    return *llvm::cast<clang::ItaniumVTableContext>(VTContext);
  }

  //   MicrosoftVTableContext &getMicrosoftVTableContext() {
  //     return *cast<MicrosoftVTableContext>(VTContext);
  //   }

  //   /// getSubVTTIndex - Return the index of the sub-VTT for the base class
  //   of the
  //   /// given record decl.
  //   uint64_t getSubVTTIndex(const CXXRecordDecl *RD, BaseSubobject Base);

  //   /// getSecondaryVirtualPointerIndex - Return the index in the VTT where
  //   the
  //   /// virtual pointer for the given subobject is located.
  //   uint64_t getSecondaryVirtualPointerIndex(const CXXRecordDecl *RD,
  //                                            BaseSubobject Base);

  //   /// GenerateConstructionVTable - Generate a construction vtable for the
  //   given
  //   /// base subobject.
  //   llvm::GlobalVariable *
  //   GenerateConstructionVTable(const CXXRecordDecl *RD, const BaseSubobject
  //   &Base,
  //                              bool BaseIsVirtual,
  //                              llvm::GlobalVariable::LinkageTypes Linkage,
  //                              VTableAddressPointsMapTy &AddressPoints);

  //   /// GetAddrOfVTT - Get the address of the VTT for the given record decl.
  //   llvm::GlobalVariable *GetAddrOfVTT(const CXXRecordDecl *RD);

  //   /// EmitVTTDefinition - Emit the definition of the given vtable.
  //   void EmitVTTDefinition(llvm::GlobalVariable *VTT,
  //                          llvm::GlobalVariable::LinkageTypes Linkage,
  //                          const CXXRecordDecl *RD);

  /// Emit the associated thunks for the given global decl.
  void buildThunks(GlobalDecl GD);

  /// Generate all the class data required to be generated upon definition of a
  /// KeyFunction. This includes the vtable, the RTTI data structure (if RTTI
  /// is enabled) and the VTT (if the class has virtual bases).
  void GenerateClassData(const clang::CXXRecordDecl *RD);

  bool isVTableExternal(const clang::CXXRecordDecl *RD);

  /// Returns the type of a vtable with the given layout. Normally a struct of
  /// arrays of pointers, with one struct element for each vtable in the vtable
  /// group.
  mlir::Type getVTableType(const clang::VTableLayout &layout);

  //   /// Generate a public facing alias for the vtable and make the vtable
  //   either
  //   /// hidden or private. The alias will have the original linkage and
  //   visibility
  //   /// of the vtable. This is used for cases under the relative vtables ABI
  //   /// when a vtable may not be dso_local.
  //   void GenerateRelativeVTableAlias(llvm::GlobalVariable *VTable,
  //                                    llvm::StringRef AliasNameRef);

  //   /// Specify a global should not be instrumented with hwasan.
  //   void RemoveHwasanMetadata(llvm::GlobalValue *GV) const;
};

} // end namespace cir
#endif
