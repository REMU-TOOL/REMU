#!/bin/bash

help() {
{ cat <<EOF

Usage: $0 <option>

Options:
    --plat <plat>       specify platform
    --includes          verilog include directories for FPGA flow
    --sources           verilog sources for FPGA flow
    --ivl-srcs          iverilog simulation sources
    --ivl-flags         iverilog flags
    --vvp-flags         vvp flags
    --cosim-ivl-srcs    iverilog co-simulation sources
    --cosim-ivl-flags   iverilog co-simulation flags
    --cosim-vvp-flags   vvp co-simulation flags

EOF
} >&2
exit 1
}

SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
REMU_DIR=$(realpath $SCRIPT_DIR/../share/remu)
EMULIB_DIR=$REMU_DIR/emulib

if [[ ! -d $REMU_DIR || ! -d $EMULIB_DIR ]]; then
    echo REMU is not properly installed. Run this script after installation. >&2
    exit 1
fi

get_includes() {
    INCLUDES=()
    INCLUDES+=($EMULIB_DIR/include)
}

get_sources() {
    if [ -z $1 ]; then
        echo Platform must be specified. >&2
        exit 1
    fi

    if [ ! -d $EMULIB_DIR/platform/$1 ]; then
        echo Unsupported platform $1. >&2
        exit 1
    fi

    SOURCES=()
    SOURCES+=($(find $EMULIB_DIR/common -name '*.v'))
    SOURCES+=($(find $EMULIB_DIR/system -name '*.v'))
    SOURCES+=($(find $EMULIB_DIR/platform/$1 -name '*.v'))
}

get_ivl_srcs() {
    IVL_SRCS=()
    IVL_SRCS+=($(find $EMULIB_DIR/sim -name '*.v'))
}

get_ivl_flags() {
    IVL_FLAGS=()
    get_includes
    for x in "${INCLUDES[@]}"; do
        IVL_FLAGS+=(-I $x)
    done
    IVL_FLAGS+=(-s remu_replay)
    IVL_FLAGS+=(-s EMU_TOP)
}

get_vvp_flags() {
    VVP_FLAGS=()
    VVP_FLAGS+=(-M $REMU_DIR)
    VVP_FLAGS+=(-m replay_ivl)
}

get_cosim_ivl_srcs() {
    COSIM_IVL_SRCS=()
    get_sources "sim"
    for x in "${SOURCES[@]}"; do
        COSIM_IVL_SRCS+=($x)
    done
    COSIM_IVL_SRCS+=($(find $REMU_DIR/cosim -name '*.v'))
}

get_cosim_ivl_flags() {
    COSIM_IVL_FLAGS=()
    get_includes
    for x in "${INCLUDES[@]}"; do
        COSIM_IVL_FLAGS+=(-I $x)
    done
    COSIM_IVL_FLAGS+=(-I $REMU_DIR/cosim/include)
    COSIM_IVL_FLAGS+=(-s sim_top)
}

get_cosim_vvp_flags() {
    COSIM_VVP_FLAGS=()
    COSIM_VVP_FLAGS+=(-M $REMU_DIR)
    COSIM_VVP_FLAGS+=(-m cosim_ivl)
}

if [ $# -eq 0 ]; then
    help
fi

ACTION=opt
PLAT=""

for arg; do
    case "$ACTION" in
    opt)
        case "$arg" in
        --plat)
            ACTION=plat
            ;;
        --includes)
            get_includes
            echo "${INCLUDES[@]}"
            exit
            ;;
        --sources)
            get_sources $PLAT
            echo "${SOURCES[@]}"
            exit
            ;;
        --ivl-srcs)
            get_ivl_srcs
            echo "${IVL_SRCS[@]}"
            exit
            ;;
        --ivl-flags)
            get_ivl_flags
            echo "${IVL_FLAGS[@]}"
            exit
            ;;
        --vvp-flags)
            get_vvp_flags
            echo "${VVP_FLAGS[@]}"
            exit
            ;;
        --cosim-ivl-srcs)
            get_cosim_ivl_srcs
            echo "${COSIM_IVL_SRCS[@]}"
            exit
            ;;
        --cosim-ivl-flags)
            get_cosim_ivl_flags
            echo "${COSIM_IVL_FLAGS[@]}"
            exit
            ;;
        --cosim-vvp-flags)
            get_cosim_vvp_flags
            echo "${COSIM_VVP_FLAGS[@]}"
            exit
            ;;
        esac
        ;;
    plat)
        PLAT=$arg
        ACTION=opt
        ;;
    esac
done
