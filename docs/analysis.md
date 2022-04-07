# Table of contents

  - [Scope of the benchmark](#scope-of-the-benchmark)
  - [Test protocol](#test-protocol)
  - [Results](#results)
    - [ENV1](#env1)
    - [ENV2](#env2,-with-mi3)
    - [Non-toy tests](#non-toy-tests)
  - [Summary](#summary)
    - [Detected errors](#detected-errors)
    - [Recommendations](#recommendations)
  - [Related work](#related-work)

# Scope of the benchmark

Memory sanitizers are tools to help finding memory access
problems. Think out of bound accesses, uninitialized variables,
allocation issues, etc. The way they work is typically by keeping a
map of valid memory ranges and checking the validity of every memory
accesses. As a side effect, this increases the CPU and memory
consumption.

The goal is to run many memory analyzers on known problematic programs
to find which tool reports which problems. The cost in term of program
execution duration is also measured.

# Test protocol

The tests consist in thirty-plus programs with intentional errors:

  - 11 allocation issues (mismatching new/delete, leaks…), later
    denoted with the prefix "alloc-".​
  - 7 array out of bounds read, prefix "oob-read-".​
  - 7 array out of bounds writes, prefix "oob-write-".​
  - 4 uses of uninitialized variable, prefix "uninit-".​
  - 1 stack use after return, prefix "misc-".​
  - 1 expected move of uninitialized memory, prefix "pass-".

These programs are compiled without optimizations, with the required
sanitizer flags when appropriate. The sanitizers considered in this
test are:

  - Address Sanitizer, with GCC.
  - Memory Sanitizer, with Clang.
  - Valgrind,
  - Intel Inspector.

Note that old versions of Inspector are tested. Ideally one should use
the latest version, but when we started this work we had a huge
performance loss by switching from 2016 to 2018, thus the need to test
as many versions as possible.

Finally, the tests are done on two computers, with different versions
of the sanitizers:

  - Environment ENV1
    - CentOS 7.8, GCC 4.8, Inspector 2016-2020, Valgrind 3.15.​
    - Intel(R) Xeon(R) CPU @ 2.30GHz​
    - Nproc = 16​
    - Clang's Memory Sanitizer is not available.
  - Environment ENV2
    - Ubuntu 21.04, GCC 10.3, Clang 12, Inspector 2020, Valgrind 3.17​
    - Hyper V, 100% cpus dedicated to VM.​
    - Intel(R) Core(TM) i7-8665U CPU @ 1.90GHz​
    - Nproc = 8

# Results

  - Inspector is launched with either `inspxe-cl -collect mi2 -knob
    detect-uninit-read=true​` (replace knob argument with `-knob
    detect-invalid-accesses=true` if using Inspector 2019 or later) or
    `inspxe-cl -collect mi3 -knob detect-uninit-read=true -knob
    analyze-stack=true​`, later denoted as _mi2_ and _mi3_.
  - Valgrind is launched with `valgrind --leak-check=yes
    --leak-resolution=low --show-reachable=no --show-possibly-lost=no
    --keep-stacktraces=none --error-exitcode=1`
  - When using Address Sanitizer, environment variable
    `ASAN_OPTIONS=detect_stack_use_after_return=1` is set, to detect
    stack use after return.​
  - When using Address Sanitizer or Memory Sanitizer, environment
    variable `MALLOC_CHECK_=0` is set to prevent issues reported by
    built-in malloc checks.

## ENV1

### With mi2

|                                    | Asan | Inspector 2016 | Inspector 2017 | Inspector 2018 | Inspector 2019 | Inspector 2020 | Valgrind |
|------------------------------------|------|----------------|----------------|----------------|----------------|----------------|----------|
|                                    | 1 s. | 3 m. 9 s.      | 3 m. 35 s.     | 3 m. 40 s.     | 3 m. 33 s.     | 3 m. 32 s.     | 9 s.     |
| alloc-use-after-delete             | ✅    | ✅              | ❌              | ✅              | ✅              | ✅              | ✅        |
| alloc-use-after-free               | ✅    | ✅              | ❌              | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-malloc-delete       | ✅    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-malloc-delete-array | ✅    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-free            | ✅    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-array-delete    | ✅    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-array-free      | ✅    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-delete-array    | ✅    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-missing-delete               | ❌    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-missing-delete-array         | ❌    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| alloc-missing-free                 | ❌    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| oob-read-global-after-end          | ✅    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-read-global-before-begin       | ❌    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-read-heap-after-end            | ✅    | ✅              | ❌              | ✅              | ✅              | ✅              | ✅        |
| oob-read-heap-before-begin         | ✅    | ✅              | ❌              | ✅              | ✅              | ✅              | ✅        |
| oob-read-stack-after-end           | ✅    | ❌              | ❌              | ❌              | ❌              | ❌              | ✅        |
| oob-read-stack-before-begin        | ✅    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-read-struct-next-field         | ❌    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-write-global-after-end         | ✅    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-write-global-before-begin      | ❌    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-write-heap-after-end           | ✅    | ✅              | ❌              | ✅              | ✅              | ✅              | ✅        |
| oob-write-heap-before-begin        | ✅    | ✅              | ❌              | ✅              | ✅              | ✅              | ✅        |
| oob-write-stack-after-end          | ✅    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-write-stack-before-begin       | ✅    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| oob-write-struct-next-field        | ❌    | ❌              | ❌              | ❌              | ❌              | ❌              | ❌        |
| uninit-read-bit                    | ❌    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| uninit-read-heap-variable          | ❌    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| uninit-read-malloc-variable        | ❌    | ✅              | ✅              | ✅              | ✅              | ✅              | ✅        |
| uninit-read-stack-variable         | ❌    | ❌              | ❌              | ❌              | ❌              | ❌              | ✅        |
| misc-stack-use-after-return        | ❌    | ❌              | ❌              | ❌              | ❌              | ❌              | ✅        |
| pass-simd                          | ✅    | ❌              | ❌              | ❌              | ❌              | ✅              | ✅        |

In terms of accuracy, Address Sanitizer finds errors not found by
others but misses some of the others; Valgrind finds the most errors;​
Inspector before 2020 reports the false positive.

In terms of speed, Address Sanitizer is the fastest, followed by
Valgrind, then far behind by Inspector.

### With mi3

|                                    | Asan | Inspector 2016   | Inspector 2017   | Inspector 2018 | Inspector 2019 | Inspector 2020 | Valgrind |
|------------------------------------|------|------------------|------------------|----------------|----------------|----------------|----------|
|                                    | 1 s. | 1 h. 21 m. 49 s. | 1 h. 24 m. 20 s. | 3 m. 21 s.     | 3 m. 29 s.     | 3 m. 14 s.     | 9 s.     |
| alloc-use-after-delete             | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-use-after-free               | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-malloc-delete       | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-malloc-delete-array | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-free            | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-array-delete    | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-array-free      | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-mismatch-new-delete-array    | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-missing-delete               | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-missing-delete-array         | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| alloc-missing-free                 | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| oob-read-global-after-end          | ✅    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-read-global-before-begin       | ❌    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-read-heap-after-end            | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| oob-read-heap-before-begin         | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| oob-read-stack-after-end           | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| oob-read-stack-before-begin        | ✅    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-read-struct-next-field         | ❌    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-write-global-after-end         | ✅    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-write-global-before-begin      | ❌    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-write-heap-after-end           | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| oob-write-heap-before-begin        | ✅    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| oob-write-stack-after-end          | ✅    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-write-stack-before-begin       | ✅    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| oob-write-struct-next-field        | ❌    | 💀                | 💀                | ❌              | ❌              | ❌              | ❌        |
| uninit-read-bit                    | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| uninit-read-heap-variable          | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| uninit-read-malloc-variable        | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| uninit-read-stack-variable         | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| misc-stack-use-after-return        | ❌    | 💀                | 💀                | ✅              | ✅              | ✅              | ✅        |
| pass-simd                          | ✅    | 💀                | 💀                | ❌              | ❌              | ✅              | ✅        |

Note that the results of Address Sanitizer and Valgrind should not,
and do not, differ from the previous test. The change affects only the
behavior of Inspector. In terms of accuracy, Inspector 2020 is back to
the level of Valgrind. Inspector 2016 and 2017 cannot run the tests
(it takes forever and do not output any result), and Inspector 2018
and 2019 still report the false positive.

In terms of speed, this is approximately the same as before.

## ENV2, with mi3

|                                    | Asan | Inspector 2020 | Msan | Valgrind |
|------------------------------------|------|----------------|------|----------|
|                                    | 0 s. | 3 m. 0 s.      | 1 s. | 16 s.    |
| alloc-use-after-delete             | ✅    | ✅              | ❌    | ✅        |
| alloc-use-after-free               | ✅    | ✅              | ❌    | ✅        |
| alloc-mismatch-malloc-delete       | ✅    | ✅              | ❌    | ✅        |
| alloc-mismatch-malloc-delete-array | ✅    | ✅              | ❌    | ✅        |
| alloc-mismatch-new-free            | ✅    | ✅              | ❌    | ✅        |
| alloc-mismatch-new-array-delete    | ✅    | ✅              | ❌    | ✅        |
| alloc-mismatch-new-array-free      | ✅    | ✅              | ❌    | ✅        |
| alloc-mismatch-new-delete-array    | ✅    | ✅              | ❌    | ✅        |
| alloc-missing-delete               | ✅    | ✅              | ❌    | ✅        |
| alloc-missing-delete-array         | ✅    | ✅              | ❌    | ✅        |
| alloc-missing-free                 | ✅    | ✅              | ❌    | ✅        |
| oob-read-global-after-end          | ✅    | ❌              | ❌    | ❌        |
| oob-read-global-before-begin       | ❌    | ❌              | ❌    | ❌        |
| oob-read-heap-after-end            | ✅    | ✅              | ❌    | ✅        |
| oob-read-heap-before-begin         | ✅    | ✅              | ✅    | ✅        |
| oob-read-stack-after-end           | ✅    | ✅              | ❌    | ✅        |
| oob-read-stack-before-begin        | ✅    | ❌              | ❌    | ❌        |
| oob-read-struct-next-field         | ❌    | ❌              | ❌    | ❌        |
| oob-write-global-after-end         | ✅    | ❌              | ❌    | ❌        |
| oob-write-global-before-begin      | ❌    | ❌              | ❌    | ❌        |
| oob-write-heap-after-end           | ✅    | ✅              | ❌    | ✅        |
| oob-write-heap-before-begin        | ✅    | ✅              | ✅    | ✅        |
| oob-write-stack-after-end          | ✅    | ❌              | ❌    | ❌        |
| oob-write-stack-before-begin       | ✅    | ❌              | ❌    | ❌        |
| oob-write-struct-next-field        | ❌    | ❌              | ❌    | ❌        |
| uninit-read-bit                    | ❌    | ✅              | ❌    | ✅        |
| uninit-read-heap-variable          | ❌    | ✅              | ❌    | ✅        |
| uninit-read-malloc-variable        | ❌    | ✅              | ❌    | ✅        |
| uninit-read-stack-variable         | ❌    | ✅              | ❌    | ✅        |
| misc-stack-use-after-return        | ✅    | ✅              | ❌    | ✅        |
| pass-simd                          | ✅    | ✅              | ✅    | ✅        |

In terms of accuracy, Inspector and Valgrind find the same
errors. They also find problems that Address Sanitizer does not, and
the latter also finds problems not found by the former. Memory
Sanitizer does not find many errors, and these errors are already
found as efficiently by other tools.

In terms of speed, Address Sanitizer stays the fastest, followed by
Valgrind, then by Inspector.

# Non-toy tests

In order to get some insight on the impact of the tools on the
program's execution time, we have tested them on a video encoder, with
the following time measures.

| **H264**           | FPS       | Total time |
|--------------------|-----------|------------|
| No sanitizer       | 68.65 fps | 0m1.880    |
| Address Sanitizer  | 21.97 fps | 0m5.834s   |
| Valgrind           | 0.38 fps  | 4m43.571s  |
| Inspector 2020 mi3 | 0.40 fps  | 5m1.327s   |

| **HEVC**           | FPS       | Total time |
|--------------------|-----------|------------|
| No sanitizer       | 46.76 fps | 0m2,799s   |
| Address Sanitizer  | 15.18 fps | 0m37,720s  |
| Valgrind           | 0.06 fps  | 28m16,380s |
| Inspector 2020 mi3 | 0.07 fps  | 24m42,209s |

The efficiency of Address Sanitizer is confirmed by these
measures. Valgrind and Inspector have similar overhead.

# Summary

## Detected errors

 - Address Sanitizer is fast and finds errors not found by others.
 - Valgrind and Inspector are slow and find errors not found by
   Address Sanitizer.
 - Some errors are never detected:
   - Out of bounds access to an array in a struct. Reported as a
     warning with GCC 10 though.
   - Underflow in global variable (only the first one?
     https://github.com/google/sanitizers/issues/869)

## Recommendations

 - Prefer Valgrind or Inspector 2020 over Inspector 2016-2019.
 - Use GCC and Address Sanitizer for day-to-day development.
 - Run the tests twice: with Address Sanitizer, and with Valgrind or
   Inspector 2020
   - Requires two compilations.
   - Tests covered by Address Sanitizer may be disabled in Inspector.

# Related work

  - [AddressSanitizer: A Fast Address Sanity Checker. USENIX ATC 2012](https://static.googleusercontent.com/media/research.google.com/fr//pubs/archive/37752.pdf​)
  - [Memory error checking in C and C++: Comparing Sanitizers and Valgrind](https://developers.redhat.com/blog/2021/05/05/memory-error-checking-in-c-and-c-comparing-sanitizers-and-valgrind​)
  - [Valgrind - A neglected tool from the shadows or a serious debugging tool?
](https://m-peko.github.io/craft-cpp/posts/valgrind-a-neglected-tool-from-the-shadows-or-a-serious-debugging-tool/)

