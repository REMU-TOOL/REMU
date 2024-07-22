#!/bin/sh

# Check the number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <name> <generator> <target>"
    exit 1
fi

top_name="$1"
gen="$2"
target="$3"

mkdir $(dirname $target)

$gen > $target

script_dir="$(dirname "$(readlink -f "$0")")"

TOP_NAME=$top_name BUILD_DIR=$(dirname $target) make -f $script_dir/verilator.mk 



