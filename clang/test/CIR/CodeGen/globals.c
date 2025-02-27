// There seems to be some differences in how constant expressions are evaluated
// in C vs C++. This causees the code gen for C initialized globals to be a
// bit different from the C++ version. This test ensures that these differences
// are accounted for.

// RUN: %clang_cc1 -triple x86_64-unknown-linux-gnu -emit-cir %s -o - | FileCheck %s

char string[] = "whatnow";
// CHECK: cir.global external @string = #cir.const_array<"whatnow\00" : !cir.array<!s8i x 8>> : !cir.array<!s8i x 8>
int sint[] = {123, 456, 789};
// CHECK: cir.global external @sint = #cir.const_array<[#cir.int<123> : !s32i, #cir.int<456> : !s32i, #cir.int<789> : !s32i]> : !cir.array<!s32i x 3>
int filler_sint[4] = {1, 2}; // Ensure missing elements are zero-initialized.
// CHECK: cir.global external @filler_sint = #cir.const_array<[#cir.int<1> : !s32i, #cir.int<2> : !s32i, #cir.int<0> : !s32i, #cir.int<0> : !s32i]> : !cir.array<!s32i x 4>
int excess_sint[2] = {1, 2, 3, 4}; // Ensure excess elements are ignored.
// CHECK: cir.global external @excess_sint = #cir.const_array<[#cir.int<1> : !s32i, #cir.int<2> : !s32i]> : !cir.array<!s32i x 2>
