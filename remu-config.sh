#!/bin/bash

help() {
{ cat <<EOF

Usage: $0 <option>

Options:
    --ivl-srcs          simulation sources for iverilog
    --ivl-flags         iverilog flags
    --vvp-flags         vvp flags
    --cosim-ivl-flags   iverilog flags for co-simulation
    --cosim-vvp-flags   vvp flags for co-simulation

EOF
} >&2
exit 1
}

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
REMU_DIR=$(realpath $SCRIPT_DIR/../share/remu)
EMULIB_DIR=$REMU_DIR/emulib

if [[ ! -d $REMU_DIR || ! -d $EMULIB_DIR ]]; then
    echo REMU is not properly installed. Run this script after installation.
    exit 1
fi

IVL_SRCS=$(find $EMULIB_DIR/sim -name "*.v")
IVL_FLAGS="-I $EMULIB_DIR/include -s reconstruct"
VVP_FLAGS="-M $REMU_DIR -m replay"
COSIM_IVL_FLAGS="-I $REMU_DIR/cosim"
COSIM_VVP_FLAGS="-M $REMU_DIR -m cosim_ivl"

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
        --cosim-ivl-flags)
            echo $COSIM_IVL_FLAGS
            exit
        ;;
        --cosim-vvp-flags)
            echo $COSIM_VVP_FLAGS
            exit
        ;;
    esac
done
