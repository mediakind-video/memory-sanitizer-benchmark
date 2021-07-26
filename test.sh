#!/bin/bash

set -e

run_valgrind=1
run_asan=1
run_msan=1
run_inspector=1
run_inspector_version[2016]=1
run_inspector_version[2017]=1
run_inspector_version[2018]=1
run_inspector_version[2019]=1
run_inspector_version[2020]=1
inspector_analysis=mi2

intel_root="$HOME/intel"

working_directory="$(pwd)"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
this_script="${script_dir}/$(basename "${BASH_SOURCE[0]}")"

function usage()
{
    cat - <<EOF
Run the sanitizer tests found in the build directory.

Usage: $0 [ OPTION ]

Where OPTION is:
  -h, --help
      Display this message and exit.
  --skip-asan
      Do not run the tests compiled with Address Sanitizer.
  --skip-inspector
      Do not run the tests via Intel Inspector. Specify the version to exclude
      only this version, e.g. --skip-inspector-2017.
  --skip-msan
      Do not run the tests compiled with memory Sanitizer.
  --skip-valgrind
      Do not run the tests via Valgrind.
  --inspector-analysis=[ mi2, mi3 ]
      Run the given analysis with Intel Inspector.
      Default is $inspector_analysis.
EOF
}

# Launch a command to test and display a line with the program name
# followed by either 1 or 0 if the command has respectively failed or
# succeeded.
#
# Arguments are:
# - $1: a tag to used to identify the tool. The command output will be
#   redirected to $log_dir/$1/$program_name.
# - --launcher-begin arg… --launcher-end: the command that launches the
#   program.
# - --no-problem: inverse the exit code. 0 is displayed if the command
#   has failed, 1 otherwise.
# - rest: the program to test.
#
# The order of the arguments matters.
#
function check_failure()
{
    local tag="$1"
    shift

    local launcher=()

    if [[ "$1" == "--launcher-begin" ]]
    then
        shift
        while [[ "$1" != "--launcher-end" ]]
        do
            launcher+=("$1")
            shift
        done
        shift
    fi

    local success
    local error
    local failure=2

    if [[ "$1" == "--no-problem" ]]
    then
        success=1
        error=0
        shift
    else
        success=0
        error=1
    fi

    local program_name="$1"

    mkdir -p "$log_dir/$tag"

    local log_file="$log_dir/$tag/$program_name.log"

    # Disable default checks from malloc() as we want them to be
    # detected by the tool instead.
    if MALLOC_CHECK_=0 "${launcher[@]}" "$@" &> "$log_file"
    then
        echo -e "$program_name $success"
    elif grep --quiet --max-count 1 'Run terminated abnormally' "$log_file"
    then
        # Sometimes Inspector fails.
        echo -e "$program_name $failure"
    else
        echo -e "$program_name $error"
    fi
}

function run_tests()
{
    local tag="$1"
    shift

    local launcher=("$@")
    local command=(check_failure "$tag"
                   --launcher-begin "${launcher[@]}" --launcher-end)

    local start
    start="$(date +%s)"

    "${command[@]}" ./alloc-use-after-delete 1 2
    "${command[@]}" ./alloc-use-after-free 1 2
    "${command[@]}" ./alloc-mismatch-malloc-delete 1 2
    "${command[@]}" ./alloc-mismatch-malloc-delete-array 1 2
    "${command[@]}" ./alloc-mismatch-new-free 1 2
    "${command[@]}" ./alloc-mismatch-new-array-delete 1 2
    "${command[@]}" ./alloc-mismatch-new-array-free 1 2
    "${command[@]}" ./alloc-mismatch-new-delete-array 1 2
    "${command[@]}" ./alloc-missing-delete 1 2
    "${command[@]}" ./alloc-missing-delete-array 1 2
    "${command[@]}" ./alloc-missing-free 1 2

    "${command[@]}" ./oob-read-heap-after-end 1 2 3 4
    "${command[@]}" ./oob-read-heap-before-begin
    "${command[@]}" ./oob-read-stack-after-end 1 2 3 4
    "${command[@]}" ./oob-read-stack-before-begin
    "${command[@]}" ./oob-read-struct-next-field 1 2 3 4

    "${command[@]}" ./oob-write-heap-after-end 1 2 3 4
    "${command[@]}" ./oob-write-heap-before-begin
    "${command[@]}" ./oob-write-stack-after-end 1 2 3 4
    "${command[@]}" ./oob-write-stack-before-begin
    "${command[@]}" ./oob-write-struct-next-field 1 2 3 4

    "${command[@]}" ./uninit-read-bit 1 2
    "${command[@]}" ./uninit-read-heap-variable 1 2
    "${command[@]}" ./uninit-read-malloc-variable 1 2
    "${command[@]}" ./uninit-read-stack-variable 1 2

    "${command[@]}" --no-problem ./pass-simd 1

    local end
    end="$(date +%s)"

    local total_seconds=$((end - start))
    local seconds=$((total_seconds % 60))
    local minutes=$((total_seconds / 60 % 60))
    local hours=$((total_seconds / 3600))

    printf "Done in "

    if [[ "$hours" -ne 0 ]]
    then
        printf "%s h. %s m. %s s.\n" "$hours" "$minutes" "$seconds"
    elif [[ "$minutes" -ne 0 ]]
    then
        printf "%s m. %s s.\n" "$minutes" "$seconds"
    else
        printf "%s s.\n" "$seconds"
    fi
}

function run_all_inspector_tests()
{
    local version="$1"

    if [[ "${run_inspector_version[$version]}" -ne 1 ]]
    then
        return
    fi

    local inspector_path_prefix="$intel_root/$version/inspector_"
    local inspector
    inspector="$(echo "$inspector_path_prefix"*"$version"/bin64/inspxe-cl)"

    local args=()

    if [[ "$version" -ge 2019 ]]
    then
        args+=(-knob detect-invalid-accesses=true)
    else
        args+=(-knob detect-uninit-read=true)
    fi

    if [[ "$inspector_analysis" == "mi3" ]]
    then
        args+=(-knob analyze-stack=true)
    fi

    local suppressions="$script_dir/inspector/suppressions-$version.txt"

    if [[ -f "$suppressions" ]]
    then
        args+=(-suppression-file "$suppressions")
    fi

    echo "Inspector $version"
    (
        echo "== Inspector $version =="
        run_tests inspector-"$version" "$inspector" \
                  -collect "$inspector_analysis" \
                  -result-dir "$log_dir/r$version-@@@{at}" \
                  "${args[@]}" \

    ) > "$log_dir/inspector-$version.log"
}

function run_all_tests()
{
    if [[ "$run_asan" -ne 0 ]]
    then
        echo "Address Sanitizer"
        cd asan
        (
            echo "== Address Sanitizer =="
            run_tests asan
        ) > "$log_dir/asan.log"
        cd - > /dev/null
    fi

    if [[ "$run_msan" -ne 0 ]]
    then
        echo "Memory Sanitizer"
        cd msan
        (
            echo "== Memory Sanitizer =="
            run_tests msan
        ) > "$log_dir/msan.log"
        cd - > /dev/null
    fi

    cd default

    if [[ "$run_valgrind" -ne 0 ]]
    then
        echo "Valgrind"
        (
            echo "== Valgrind =="

            # We need to pass --leak-check=full for Valgrind to exit
            # with the error exit code on memory leaks. Otherwise the
            # leak is reported but the exit code is still zero.
            run_tests valgrind valgrind \
                      --leak-check=yes \
                      --leak-resolution=low \
                      --show-reachable=no \
                      --show-possibly-lost=no \
                      --keep-stacktraces=none \
                      --error-exitcode=1

        ) > "$log_dir/valgrind.log"
    fi

    if [[ "$run_inspector" -ne 0 ]]
    then
        pids=()
        (
            # Need to switch to the working directory for the log directory to
            # be correctly set by the recursive instantiation.
            cd "$working_directory"

            for version in 2016 2017 2018 2019 2020
            do
                "$this_script" \
                    --inspector-"$version" \
                    --inspector-analysis="$inspector_analysis" &
                pids+=($!)
            done

            for p in "${pids[@]}"
            do
                wait "$p"
            done
        )
    fi

    cd - > /dev/null
}

for arg in "$@"
do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        --skip-asan)
            run_asan=0
            ;;
        --skip-inspector)
            run_inspector=0
            ;;
        --skip-inspector-*)
            run_inspector_version[${arg#--skip-inspector-}]=0
            ;;
        --skip-msan)
            run_msan=0
            ;;
        --skip-valgrind)
            run_valgrind=0
            ;;
        --inspector-analysis=*)
            inspector_analysis="${arg#--inspector-analysis=}"
            ;;
        --inspector-*)
            run_inspector_only="${arg#--inspector-}"
            ;;
        *)
            echo "Unhandled argument: '$arg'." >&2
            exit 1
    esac
done

log_dir="$working_directory/logs-${inspector_analysis}"

if [[ -n "$run_inspector_only" ]]
then
    # This case should only occur from a recursive instantiation, thus
    # we can assume that the setup is done.
    cd "$script_dir/build/default"
    run_all_inspector_tests "$run_inspector_only"
else
    mkdir -p "$log_dir"

    cd "$script_dir/build"

    run_all_tests
fi
