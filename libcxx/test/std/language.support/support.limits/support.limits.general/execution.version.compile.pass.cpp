//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// WARNING: This test was generated by generate_feature_test_macro_components.py
// and should not be edited manually.
//
// clang-format off

// <execution>

// Test the feature test macros defined by <execution>

/*  Constant               Value
    __cpp_lib_execution    201603L [C++17]
                           201902L [C++20]
*/

#include <execution>
#include "test_macros.h"

#if TEST_STD_VER < 14

# ifdef __cpp_lib_execution
#   error "__cpp_lib_execution should not be defined before c++17"
# endif

#elif TEST_STD_VER == 14

# ifdef __cpp_lib_execution
#   error "__cpp_lib_execution should not be defined before c++17"
# endif

#elif TEST_STD_VER == 17

# if !defined(_LIBCPP_VERSION)
#   ifndef __cpp_lib_execution
#     error "__cpp_lib_execution should be defined in c++17"
#   endif
#   if __cpp_lib_execution != 201603L
#     error "__cpp_lib_execution should have the value 201603L in c++17"
#   endif
# else // _LIBCPP_VERSION
#   ifdef __cpp_lib_execution
#     error "__cpp_lib_execution should not be defined because it is unimplemented in libc++!"
#   endif
# endif

#elif TEST_STD_VER == 20

# if !defined(_LIBCPP_VERSION)
#   ifndef __cpp_lib_execution
#     error "__cpp_lib_execution should be defined in c++20"
#   endif
#   if __cpp_lib_execution != 201902L
#     error "__cpp_lib_execution should have the value 201902L in c++20"
#   endif
# else // _LIBCPP_VERSION
#   ifdef __cpp_lib_execution
#     error "__cpp_lib_execution should not be defined because it is unimplemented in libc++!"
#   endif
# endif

#elif TEST_STD_VER > 20

# if !defined(_LIBCPP_VERSION)
#   ifndef __cpp_lib_execution
#     error "__cpp_lib_execution should be defined in c++23"
#   endif
#   if __cpp_lib_execution != 201902L
#     error "__cpp_lib_execution should have the value 201902L in c++23"
#   endif
# else // _LIBCPP_VERSION
#   ifdef __cpp_lib_execution
#     error "__cpp_lib_execution should not be defined because it is unimplemented in libc++!"
#   endif
# endif

#endif // TEST_STD_VER > 20

