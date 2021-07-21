project(sanitizer-benchmark)

cmake_minimum_required(VERSION 3.14)

set(CMAKE_CXX_STANDARD 11)

if("${CMAKE_BUILD_TYPE}" STREQUAL Debug)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0")
else()
  message(
    WARNING
    "Using a non-debug build may trigger optimizations that would moot the \
tests."
    )
endif()

option(ENABLE_ASAN "Enable address sanitizer" OFF)
option(ENABLE_MSAN "Enable memory sanitizer" OFF)

if(ENABLE_ASAN)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address")
endif()

if(ENABLE_MSAN)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=memory")
endif()

function(add_test_executable prefix source)
  get_filename_component(executable_name ${source} NAME_WE)

  add_executable("${prefix}${executable_name}" ${source})
endfunction()

foreach(file
    use-after-delete.cpp
    use-after-free.cpp
    mismatch-malloc-delete.cpp
    mismatch-malloc-delete-array.cpp
    mismatch-new-free.cpp
    mismatch-new-array-delete.cpp
    mismatch-new-array-free.cpp
    mismatch-new-delete-array.cpp
    missing-delete.cpp
    missing-delete-array.cpp
    missing-free.cpp
    )
  add_test_executable(alloc- "src/alloc/${file}")
endforeach()

foreach(file
    heap-after-end.cpp
    heap-before-begin.cpp
    stack-after-end.cpp
    stack-before-begin.cpp
    struct-next-field.cpp
    )
  add_test_executable(oob-read- "src/out-of-bounds-read/${file}")
  add_test_executable(oob-write- "src/out-of-bounds-write/${file}")
endforeach()

foreach(file
    bit.cpp
    heap-variable.cpp
    malloc-variable.cpp
    stack-variable.cpp
    )
  add_test_executable(uninit-read- "src/uninitialized-read/${file}")
endforeach()

foreach(file
    simd.cpp
    )
  add_test_executable(pass- "src/pass/${file}")
endforeach()
