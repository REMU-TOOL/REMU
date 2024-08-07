#!/bin/sh

# Check the number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <generator> <target directory>"
    exit 1
fi

gen="$1"
target_dir="$2"
num_proc="$3"

mkdir -p $target_dir

$gen $target_dir/top.v $target_dir/TracePortMacro.h

script_dir="$(dirname "$(readlink -f "$0")")"

TOP_NAME=top BUILD_DIR=$target_dir make -f $script_dir/verilator.mk -j $num_proc



