// RUN: mlir-opt %s --sparse-tensor-conversion --canonicalize --cse | FileCheck %s

// RUN: mlir-opt %s --post-sparsification-rewrite="enable-runtime-library=false enable-foreach=false" \
// RUN: --canonicalize --cse | FileCheck %s --check-prefix=CHECK-RWT

#SparseVector = #sparse_tensor.encoding<{
  lvlTypes = ["compressed"]
}>

#SparseMatrix = #sparse_tensor.encoding<{
  lvlTypes = ["dense", "compressed"]
}>

#SparseTensor = #sparse_tensor.encoding<{
  lvlTypes = ["dense", "compressed", "compressed"],
  dimOrdering = affine_map<(i,j,k) -> (k,i,j)>
}>

// CHECK-LABEL: func @sparse_convert_1d(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<13xi32>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[I13:.*]] = arith.constant 13 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[C0:.*]] = arith.constant 0 : i32
//   CHECK-DAG: %[[C6:.*]] = arith.constant 6 : i32
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<1xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<1xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<1xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I13]], %[[DimSizes]][%[[I0]]] : memref<1xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<1xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %[[C0]], %[[C0]], %[[C6]], %[[C6]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<i32>
//   CHECK-DAG: %[[M:.*]] = memref.alloc() : memref<13xi32>
//   CHECK-DAG: linalg.fill ins(%[[C0]] : i32) outs(%[[M]] : memref<13xi32>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextI32(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<i32>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<1xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<i32>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]]] : memref<13xi32>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<13xi32>
//       CHECK: return %[[T]] : tensor<13xi32>
func.func @sparse_convert_1d(%arg0: tensor<13xi32, #SparseVector>) -> tensor<13xi32> {
  %0 = sparse_tensor.convert %arg0 : tensor<13xi32, #SparseVector> to tensor<13xi32>
  return %0 : tensor<13xi32>
}

// CHECK-LABEL: func @sparse_convert_1d_dyn(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<?xi32>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[C0:.*]] = arith.constant 0 : i32
//   CHECK-DAG: %[[C6:.*]] = arith.constant 6 : i32
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<1xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<1xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<1xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: %[[SizeI0:.*]] = call @sparseDimSize(%[[Arg]], %[[I0]]) : (!llvm.ptr<i8>, index) -> index
//   CHECK-DAG: memref.store %[[SizeI0]], %[[DimSizes]][%[[I0]]] : memref<1xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<1xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %[[C0]], %[[C0]], %[[C6]], %[[C6]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<1xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<1xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<i32>
//   CHECK-DAG: %[[M:.*]] = memref.alloc(%[[SizeI0]]) : memref<?xi32>
//   CHECK-DAG: linalg.fill ins(%[[C0]] : i32) outs(%[[M]] : memref<?xi32>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextI32(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<i32>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<1xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<i32>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]]] : memref<?xi32>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<?xi32>
//       CHECK: return %[[T]] : tensor<?xi32>
func.func @sparse_convert_1d_dyn(%arg0: tensor<?xi32, #SparseVector>) -> tensor<?xi32> {
  %0 = sparse_tensor.convert %arg0 : tensor<?xi32, #SparseVector> to tensor<?xi32>
  return %0 : tensor<?xi32>
}

// CHECK-LABEL: func @sparse_convert_2d(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<2x4xf64>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[I1:.*]] = arith.constant 1 : index
//   CHECK-DAG: %[[I2:.*]] = arith.constant 2 : index
//   CHECK-DAG: %[[I4:.*]] = arith.constant 4 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[ActionToIter:.*]] = arith.constant 6 : i32
//   CHECK-DAG: %[[E0:.*]] = arith.constant 0.000000e+00 : f64
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<2xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<2xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<2xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I1]]] : memref<2xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I2]], %[[DimSizes]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[I4]], %[[DimSizes]][%[[I1]]] : memref<2xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[I1]], %[[Iota]][%[[I1]]] : memref<2xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %{{.*}}, %{{.*}}, %{{.*}}, %[[ActionToIter]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<f64>
//   CHECK-DAG: %[[M:.*]] = memref.alloc() : memref<2x4xf64>
//   CHECK-DAG: linalg.fill ins(%[[E0]] : f64) outs(%[[M]] : memref<2x4xf64>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextF64(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<f64>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<2xindex>
//       CHECK:   %[[Iv1:.*]] = memref.load %[[IndS]][%[[I1]]] : memref<2xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<f64>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]], %[[Iv1]]] : memref<2x4xf64>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<2x4xf64>
//       CHECK: return %[[T]] : tensor<2x4xf64>

// CHECK-RWT-LABEL: func.func @sparse_convert_2d(
//  CHECK-RWT-SAME: %[[A:.*]]: tensor<2x4xf64, #sparse_tensor.encoding<{ lvlTypes = [ "dense", "compressed" ] }>>) -> tensor<2x4xf64> {
//       CHECK-RWT: %[[F0:.*]] = arith.constant 0.000000e+00 : f64
//       CHECK-RWT: %[[B:.*]] = memref.alloc() : memref<2x4xf64>
//       CHECK-RWT: linalg.fill ins(%[[F0]] : f64) outs(%[[B]]
//       CHECK-RWT: sparse_tensor.foreach in %[[A]]
//       CHECK-RWT: ^bb0(%[[FI0:.*]]: index, %[[FI1:.*]]: index, %[[FV:.*]]: f64):
//       CHECK-RWT:   memref.store %[[FV]], %[[B]]{{\[}}%[[FI0]], %[[FI1]]]
//       CHECK-RWT: }
//       CHECK-RWT: %[[T:.*]] = bufferization.to_tensor %[[B]]
//       CHECK-RWT: return %[[T]] : tensor<2x4xf64>
func.func @sparse_convert_2d(%arg0: tensor<2x4xf64, #SparseMatrix>) -> tensor<2x4xf64> {
  %0 = sparse_tensor.convert %arg0 : tensor<2x4xf64, #SparseMatrix> to tensor<2x4xf64>
  return %0 : tensor<2x4xf64>
}

// CHECK-LABEL: func @sparse_convert_2d_dyn0(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<?x4xf64>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[I1:.*]] = arith.constant 1 : index
//   CHECK-DAG: %[[I4:.*]] = arith.constant 4 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[ActionToIter:.*]] = arith.constant 6 : i32
//   CHECK-DAG: %[[E0:.*]] = arith.constant 0.000000e+00 : f64
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<2xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<2xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<2xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I1]]] : memref<2xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[SizeI0:.*]] = call @sparseDimSize(%[[Arg]], %[[I0]]) : (!llvm.ptr<i8>, index) -> index
//   CHECK-DAG: memref.store %[[SizeI0]], %[[DimSizes]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[I4]], %[[DimSizes]][%[[I1]]] : memref<2xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[I1]], %[[Iota]][%[[I1]]] : memref<2xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %{{.*}}, %{{.*}}, %{{.*}}, %[[ActionToIter]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<f64>
//   CHECK-DAG: %[[M:.*]] = memref.alloc(%[[SizeI0]]) : memref<?x4xf64>
//   CHECK-DAG: linalg.fill ins(%[[E0]] : f64) outs(%[[M]] : memref<?x4xf64>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextF64(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<f64>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<2xindex>
//       CHECK:   %[[Iv1:.*]] = memref.load %[[IndS]][%[[I1]]] : memref<2xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<f64>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]], %[[Iv1]]] : memref<?x4xf64>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<?x4xf64>
//       CHECK: return %[[T]] : tensor<?x4xf64>
func.func @sparse_convert_2d_dyn0(%arg0: tensor<?x4xf64, #SparseMatrix>) -> tensor<?x4xf64> {
  %0 = sparse_tensor.convert %arg0 : tensor<?x4xf64, #SparseMatrix> to tensor<?x4xf64>
  return %0 : tensor<?x4xf64>
}

// CHECK-LABEL: func @sparse_convert_2d_dyn1(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<2x?xf64>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[I1:.*]] = arith.constant 1 : index
//   CHECK-DAG: %[[I2:.*]] = arith.constant 2 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[ActionToIter:.*]] = arith.constant 6 : i32
//   CHECK-DAG: %[[E0:.*]] = arith.constant 0.000000e+00 : f64
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<2xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<2xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<2xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I1]]] : memref<2xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[SizeI1:.*]] = call @sparseDimSize(%[[Arg]], %[[I1]]) : (!llvm.ptr<i8>, index) -> index
//   CHECK-DAG: memref.store %[[I2]], %[[DimSizes]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[SizeI1]], %[[DimSizes]][%[[I1]]] : memref<2xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[I1]], %[[Iota]][%[[I1]]] : memref<2xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %{{.*}}, %{{.*}}, %{{.*}}, %[[ActionToIter]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<f64>
//   CHECK-DAG: %[[M:.*]] = memref.alloc(%[[SizeI1]]) : memref<2x?xf64>
//   CHECK-DAG: linalg.fill ins(%[[E0]] : f64) outs(%[[M]] : memref<2x?xf64>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextF64(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<f64>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<2xindex>
//       CHECK:   %[[Iv1:.*]] = memref.load %[[IndS]][%[[I1]]] : memref<2xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<f64>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]], %[[Iv1]]] : memref<2x?xf64>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<2x?xf64>
//       CHECK: return %[[T]] : tensor<2x?xf64>
func.func @sparse_convert_2d_dyn1(%arg0: tensor<2x?xf64, #SparseMatrix>) -> tensor<2x?xf64> {
  %0 = sparse_tensor.convert %arg0 : tensor<2x?xf64, #SparseMatrix> to tensor<2x?xf64>
  return %0 : tensor<2x?xf64>
}

// CHECK-LABEL: func @sparse_convert_2d_dyn2(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<?x?xf64>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[I1:.*]] = arith.constant 1 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[ActionToIter:.*]] = arith.constant 6 : i32
//   CHECK-DAG: %[[E0:.*]] = arith.constant 0.000000e+00 : f64
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<2xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<2xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<2xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I1]]] : memref<2xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[SizeI0:.*]] = call @sparseDimSize(%[[Arg]], %[[I0]]) : (!llvm.ptr<i8>, index) -> index
//   CHECK-DAG: %[[SizeI1:.*]] = call @sparseDimSize(%[[Arg]], %[[I1]]) : (!llvm.ptr<i8>, index) -> index
//   CHECK-DAG: memref.store %[[SizeI0]], %[[DimSizes]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[SizeI1]], %[[DimSizes]][%[[I1]]] : memref<2xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<2xindex>
//   CHECK-DAG: memref.store %[[I1]], %[[Iota]][%[[I1]]] : memref<2xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %{{.*}}, %{{.*}}, %{{.*}}, %[[ActionToIter]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<2xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<2xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<f64>
//   CHECK-DAG: %[[M:.*]] = memref.alloc(%[[SizeI0]], %[[SizeI1]]) : memref<?x?xf64>
//   CHECK-DAG: linalg.fill ins(%[[E0]] : f64) outs(%[[M]] : memref<?x?xf64>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextF64(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<f64>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<2xindex>
//       CHECK:   %[[Iv1:.*]] = memref.load %[[IndS]][%[[I1]]] : memref<2xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<f64>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]], %[[Iv1]]] : memref<?x?xf64>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<?x?xf64>
//       CHECK: return %[[T]] : tensor<?x?xf64>

// CHECK-RWT-LABEL: func.func @sparse_convert_2d_dyn2(
//  CHECK-RWT-SAME: %[[A:.*]]: tensor<?x?xf64, #sparse_tensor.encoding<{ lvlTypes = [ "dense", "compressed" ] }>>) -> tensor<?x?xf64> {
//   CHECK-RWT-DAG: %[[C0:.*]] = arith.constant 0 : index
//   CHECK-RWT-DAG: %[[C1:.*]] = arith.constant 1 : index
//   CHECK-RWT-DAG: %[[F0:.*]] = arith.constant 0.000000e+00 : f64
//       CHECK-RWT: %[[D0:.*]] = tensor.dim %[[A]], %[[C0]]
//       CHECK-RWT: %[[D1:.*]] = tensor.dim %[[A]], %[[C1]]
//       CHECK-RWT: %[[B:.*]] = memref.alloc(%[[D0]], %[[D1]])
//       CHECK-RWT: linalg.fill ins(%[[F0]] : f64) outs(%[[B]]
//       CHECK-RWT: sparse_tensor.foreach in %[[A]]
//       CHECK-RWT: ^bb0(%[[FI0:.*]]: index, %[[FI1:.*]]: index, %[[FV:.*]]: f64):
//       CHECK-RWT:   memref.store %[[FV]], %[[B]]{{\[}}%[[FI0]], %[[FI1]]]
//       CHECK-RWT: }
//       CHECK-RWT: %[[T:.*]] = bufferization.to_tensor %[[B]]
//       CHECK-RWT: return %[[T]] : tensor<?x?xf64>
func.func @sparse_convert_2d_dyn2(%arg0: tensor<?x?xf64, #SparseMatrix>) -> tensor<?x?xf64> {
  %0 = sparse_tensor.convert %arg0 : tensor<?x?xf64, #SparseMatrix> to tensor<?x?xf64>
  return %0 : tensor<?x?xf64>
}

// CHECK-LABEL: func @sparse_convert_3d(
//  CHECK-SAME: %[[Arg:.*]]: !llvm.ptr<i8>) -> tensor<2x3x4xf64>
//   CHECK-DAG: %[[I0:.*]] = arith.constant 0 : index
//   CHECK-DAG: %[[I1:.*]] = arith.constant 1 : index
//   CHECK-DAG: %[[I2:.*]] = arith.constant 2 : index
//   CHECK-DAG: %[[I3:.*]] = arith.constant 3 : index
//   CHECK-DAG: %[[I4:.*]] = arith.constant 4 : index
//   CHECK-DAG: %[[DenseDLT:.*]] = arith.constant 4 : i8
//   CHECK-DAG: %[[ActionToIter:.*]] = arith.constant 6 : i32
//   CHECK-DAG: %[[E0:.*]] = arith.constant 0.000000e+00 : f64
//
//   CHECK-DAG: %[[LvlTypes:.*]] = memref.alloca() : memref<3xi8>
//   CHECK-DAG: %[[LvlTypesP:.*]] = memref.cast %[[LvlTypes]] : memref<3xi8> to memref<?xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I0]]] : memref<3xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I1]]] : memref<3xi8>
//   CHECK-DAG: memref.store %[[DenseDLT]], %[[LvlTypes]][%[[I2]]] : memref<3xi8>
//   CHECK-DAG: %[[DimSizes:.*]] = memref.alloca() : memref<3xindex>
//   CHECK-DAG: %[[DimSizesP:.*]] = memref.cast %[[DimSizes]] : memref<3xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I2]], %[[DimSizes]][%[[I0]]] : memref<3xindex>
//   CHECK-DAG: memref.store %[[I3]], %[[DimSizes]][%[[I1]]] : memref<3xindex>
//   CHECK-DAG: memref.store %[[I4]], %[[DimSizes]][%[[I2]]] : memref<3xindex>
//   CHECK-DAG: %[[LvlSizes:.*]] = memref.alloca() : memref<3xindex>
//   CHECK-DAG: %[[LvlSizesP:.*]] = memref.cast %[[LvlSizes]] : memref<3xindex> to memref<?xindex>
//   CHECK-DAG: %[[Iota:.*]] = memref.alloca() : memref<3xindex>
//   CHECK-DAG: %[[IotaP:.*]] = memref.cast %[[Iota]] : memref<3xindex> to memref<?xindex>
//   CHECK-DAG: memref.store %[[I0]], %[[Iota]][%[[I0]]] : memref<3xindex>
//   CHECK-DAG: memref.store %[[I1]], %[[Iota]][%[[I1]]] : memref<3xindex>
//   CHECK-DAG: memref.store %[[I2]], %[[Iota]][%[[I2]]] : memref<3xindex>
//       CHECK: %[[Iter:.*]] = call @newSparseTensor(%[[DimSizesP]], %[[LvlSizesP]], %[[LvlTypesP]], %[[IotaP]], %[[IotaP]], %{{.*}}, %{{.*}}, %{{.*}}, %[[ActionToIter]], %[[Arg]])
//
//   CHECK-DAG: %[[IndS:.*]] = memref.alloca() : memref<3xindex>
//   CHECK-DAG: %[[IndD:.*]] = memref.cast %[[IndS]] : memref<3xindex> to memref<?xindex>
//   CHECK-DAG: %[[ElemBuffer:.*]] = memref.alloca() : memref<f64>
//   CHECK-DAG: %[[M:.*]] = memref.alloc() : memref<2x3x4xf64>
//   CHECK-DAG: linalg.fill ins(%[[E0]] : f64) outs(%[[M]] : memref<2x3x4xf64>)
//       CHECK: scf.while : () -> () {
//       CHECK:   %[[Cond:.*]] = func.call @getNextF64(%[[Iter]], %[[IndD]], %[[ElemBuffer]]) : (!llvm.ptr<i8>, memref<?xindex>, memref<f64>) -> i1
//       CHECK:   scf.condition(%[[Cond]])
//       CHECK: } do {
//       CHECK:   %[[Iv0:.*]] = memref.load %[[IndS]][%[[I0]]] : memref<3xindex>
//       CHECK:   %[[Iv1:.*]] = memref.load %[[IndS]][%[[I1]]] : memref<3xindex>
//       CHECK:   %[[Iv2:.*]] = memref.load %[[IndS]][%[[I2]]] : memref<3xindex>
//       CHECK:   %[[ElemVal:.*]] = memref.load %[[ElemBuffer]][] : memref<f64>
//       CHECK:   memref.store %[[ElemVal]], %[[M]][%[[Iv0]], %[[Iv1]], %[[Iv2]]] : memref<2x3x4xf64>
//       CHECK:   scf.yield
//       CHECK: }
//       CHECK: %[[T:.*]] = bufferization.to_tensor %[[M]] : memref<2x3x4xf64>
//       CHECK: return %[[T]] : tensor<2x3x4xf64>
func.func @sparse_convert_3d(%arg0: tensor<2x3x4xf64, #SparseTensor>) -> tensor<2x3x4xf64> {
  %0 = sparse_tensor.convert %arg0 : tensor<2x3x4xf64, #SparseTensor> to tensor<2x3x4xf64>
  return %0 : tensor<2x3x4xf64>
}
