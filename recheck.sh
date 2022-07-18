#!/bin/bash

help() {
{ cat <<EOF

Usage: $0 { --iv-srcs | --iv-flags | --vvp-flags | --tcl }

Options:
    --iv-srcs       simulation sources for iverilog
    --iv-flags      iverilog flags
    --vvp-flags     vvp flags

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

IV_SRCS=$(find $EMULIB_DIR/common $EMULIB_DIR/sim -name "*.v")
IV_FLAGS="-I$EMULIB_DIR/include -s reconstruct"
VVP_FLAGS="-M $RECHECK_DIR -m replay"

if [ $# -eq 0 ]; then
    help
fi

for opt; do
    case "$opt" in
        --iv-srcs)
            echo $IV_SRCS
            exit
        ;;
        --iv-flags)
            echo $IV_FLAGS
            exit
        ;;
        --vvp-flags)
            echo $VVP_FLAGS
            exit
        ;;
    esac
done
