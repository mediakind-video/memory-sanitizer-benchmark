#!/bin/bash

set -e

skip_build=0

for arg in "$@"
do
    case "$arg" in
        -h|--help)
            cat - <<EOF
"Build the test programs for all available configurations.

Usage: $0 [ --skip-build ]

Where:
  --skip-build
     Configure with CMake but do not build.
EOF
            exit 0
            ;;
        --skip-build)
            skip_build=1
            ;;
        *)
            echo "Unhandled argument: '$arg'." >&2
            ;;
    esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
cmake_args=("${script_dir}" "-DCMAKE_BUILD_TYPE=Debug")
export CXX=g++

if which clang++ &> /dev/null
then
    has_clang=1
else
    has_clang=0
fi

mkdir -p build/{default,asan}
[ "$has_clang" -eq 0 ] || mkdir -p build/msan

cd build/default
cmake "${cmake_args[@]}"
cd -

cd build/asan
cmake "${cmake_args[@]}" -DENABLE_ASAN=ON
cd -

if [ "$has_clang" -eq 1 ]
then
    cd build/msan
    CXX=clang++ cmake "${cmake_args[@]}" -DENABLE_MSAN=ON
    cd -
else
    echo "Skipping Memory Sanitizer since clang++ is not installed."
fi

if [ "$skip_build" -ne 1 ]
then
    nproc="$(nproc)"
    cmake --build build/default -j "${nproc}"
    cmake --build build/asan -j "${nproc}"

    [ ! -d build/msan ] || cmake --build build/msan -j "${nproc}"
fi
