This repository contains scripts and sample programs to test various
memory sanitizers.

The test process goes in three steps:

  1. run `./build.sh` to compile the sample programs.
  2. run `./test.sh` to run the compiled programs with the sanitizers.
  3. run `./format-logs.sh` to display the test results in a nice
     format.

Pass `--help` to any script to get more details. Pipe the output of
`./format-logs.sh` to disable the fancy output.

All tested programs either contain an intentional memory access error,
which should be detected by the sanitizer, or an operation known to be
detected as a false positive by some tools.

The tested sanitizers are:

  - Address Sanitizer, enabled via the `-fsanitize=address` of either
    GCC or Clang (whichever is the default compiler).
  - Memory Sanitizer, enabled via the `-fsanitize=memory` of Clang.
  - Valgrind,
  - Intel Inspector, from version 2016 to 2020.

The versions of Inspector are expected to be installed in
`$HOME/intel/$year`.

**[See the results](./docs/analysis.md)**
