#!/bin/bash

if [[ "$1" == -h ]] || [[ "$1" == --help ]]
then
    cat - <<EOF
Format the test results in a nice table.

Usage $0 [log_file…]

Where:
  log_file is a log file to format. By default, all .log files
     located in the logs in the same directory as this script are
     processed.

Tip: Pipe the output in the cat command to disable the colors and
checkmarks.
EOF
    exit 0
fi

function pretty_format()
{
    local escape
    escape=$(printf '\033')

    local red="${escape}[31m"
    local green="${escape}[32m"
    local gray="${escape}[37m"
    local reset="${escape}[0m"

    sed "s/\t0/\tN/g
         s/\t1/\tY/g
         s/\t2/\tF/g
         s/N/${red}✖${reset}/g
         s/Y/${green}✔${reset}/g
         s/F/${gray}☠${reset}/g"
}

if [ -t 1 ]
then
    format_command=pretty_format
else
    format_command=cat
fi

(
    if [ $# -eq 0 ]
    then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
        cat "$script_dir"/logs-mi2/*.log
    else
        cat "$@"
    fi
) \
    | awk '
# This program build columns with the result value of each program as
# reported by the test script. The log files are expected to look
# like that:
#
# == Tool name ==
# ./program_name result
# [repeated for each program]
# Done in duration.
#
# The name of the tool is extracted from the first line and is used
# as the column headers.
#
# The duration of the test is extracted from the last line and is
# displayed below the tool name.
#
# All the other lines are parsed to extract the program name and its
# result. It is expected that the programs are in the same order in
# all files. The program name is displayed in the first column.

BEGIN {
  title_count = 0
  global_line_count = 0
}

/^==/ {
  gsub(/== | ==$/, "")
  titles[title_count] = $0
  local_line_count = 0
}

/^Done in/ {
  durations[title_count] = $0
  ++title_count
}

/^\./ {
  if (local_line_count >= global_line_count)
  {
    lines[global_line_count] = $1
    ++global_line_count
  }

  lines[local_line_count] = lines[local_line_count] "\t" $2
  ++local_line_count
}

END {
  for (i=0; i != title_count; ++i)
    printf("\t%s", titles[i])
  printf("\n")

  for (i=0; i != title_count; ++i)
    printf("\t%s", durations[i])
  printf("\n")

  for (i=0; i != global_line_count; ++i)
  {
    printf("%s\n", lines[i]);
  }
}
' \
    | "$format_command" \
    | column --table --separator $'\t'
