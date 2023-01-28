#!/bin/bash

help() {
{ cat <<EOF

Usage: $0 <option>

Options:
    --ivl-srcs          simulation sources for iverilog
    --ivl-flags         iverilog flags
    --vvp-flags         vvp flags

EOF
} >&2
exit 1
}

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
RECHECK_DIR=$(realpath $SCRIPT_DIR/../share/recheck)
EMULIB_DIR=$RECHECK_DIR/emulib

if [[ ! -d $RECHECK_DIR || ! -d $EMULIB_DIR ]]; then
    echo Recheck is not properly installed. Run this script after installation.
    exit 1
fi

IVL_SRCS=$(find $EMULIB_DIR/sim -name "*.v")
IVL_FLAGS="-I $EMULIB_DIR/include -s reconstruct"
VVP_FLAGS="-M $RECHECK_DIR -m replay"

if [ $# -eq 0 ]; then
    help
fi

for opt; do
    case "$opt" in
        --ivl-srcs)
            echo $IVL_SRCS
            exit
        ;;
        --ivl-flags)
            echo $IVL_FLAGS
            exit
        ;;
        --vvp-flags)
            echo $VVP_FLAGS
            exit
        ;;
    esac
done
