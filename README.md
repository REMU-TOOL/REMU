# REMU: Replayable EMUlator

REMU is an open-source framework which speeds up debugging and verification of hardware designs via FPGA emulation.

It can transform an RTL design written in Verilog into an FPGA emulator design, and provides support for checkpointing & waveform reconstruction in a RTL simulator. The execution of the emulated hardware design on an FPGA can be paused and checkpointed at any time, and after an error is detected, a previous checkpoint can be restored and replayed in a simulator, generating a waveform of all signals within any desired time period.

REMU transforms the RTL design with `yosys` synthesis tool, by packaging the transformation passes inth a `yosys` plugin. The waveform reconstruction function is provided by a VPI module compatible with  `iverilog`. REMU also provides a series of emulation models, including clock, reset, and a memory model, which eases the setup of an emulated system from a design under test (DUT).

# Installation

To install this project, clone this repository first. After that, update the submodules using this command:

```sh
git submodule update --init --recursive
```

This project provides two installation methods. It can be built and installed into the local filesystem which provides the most convenient way to use, but it may conflict with existing installation of `yosys` and `iverilog` in your system. This can be avoid by installing with a path prefix other than `/usr/local` and a manual update to the `PATH` environment variable, or building a Docker image instead.

## Method 1. Install to local filesystem

First install the toolchain & libraries required to build this project. On Ubuntu 20.04, install the prerequisites by the following command:

```sh
sudo apt-get install -y \
    build-essential \
    autoconf \
    cmake \
    gawk \
    gperf \
    wget \
    git \
    bison \
    flex \
    pkg-config \
    python3 \
    libreadline-dev \
    tcl-dev \
    libffi-dev \
    libboost-filesystem-dev \
    libboost-python-dev \
    libboost-system-dev \
    zlib1g-dev
```

This project also requires `iverilog` (>= 11.0). This can be built from source code with the following commands:

```sh
# Run the following command outside the directory of this repository
git clone https://github.com/steveicarus/iverilog
cd iverilog
git checkout v11_0
sh autoconf.sh
./configure
# or specify a prefix different from /usr/local:
# ./configure --prefix=/new/instalation/prefix
make -j`nproc`
sudo make install
```

Now you can start building this project. This also builds the `yosys` submodule. 
```sh
cmake -DCMAKE_BUILD_TYPE=Release .
# or specify a prefix different from /usr/local:
# cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/new/instalation/prefix .
make -j`nproc`
sudo make install
```

If a custom installation prefix is used, you should make sure the `PATH` environment variable includes the `bin` directory every time you use this framework:

```sh
export PATH=$PATH:/new/instalation/prefix/bin
```

## Method 2. Build a Docker image

Build this project into a Docker image by the following command:

```sh
docker build -t remu .
```

Run the image in a Docker container:

```sh
docker run -it remu
```

# Usage

The steps described below should be followed to use REMU for hardware emulation.

## Top-level I/O

The design under test (DUT) must be instantiated in an emulation top module.
Clock ports must be marked with `remu_clock` attribute.
Reset or any other I/O ports must be marked with `remu_signal` attribute.
Any signal (not restricted to ports) can be marked with `remu_trigger` to indicate a 
break point condition, which stops the emulation when the signal is `1`.

Here is an example:

```verilog
module emu_top(
    (* remu_clock *)
    input   clk,
    (* remu_signal *)
    input   rst
);

    (* remu_trigger *)
    wire trap;

    // ...

endmodule
```

## Integrate with emulation models

REMU provides emulation models to emulate memories/peripherals in a processor system.
[design/picorv32/emu_top.v](design/picorv32/emu_top.v) is an example which integrate a PicoRV32 core with clock, reset, memory and peripheral models in REMU.

For a full list of emulation models, please refer to [Emulation Models](models.md).

## Transform DUT into an emulator design

After integration, run the following command to execute the transformation process. This assumes that you have integrated the DUT (`dut.v`) into a module named `emu_top` (`emu_top.v`), with the output design file named `emu_system.v` and the configuration file named `sysinfo.json`.

```sh
yosys -m transform -p "read_verilog emu_top.v dut.v; emu_transform -top emu_top -elab emu_elab.v -sysinfo sysinfo.json; write_verilog emu_system.v"
```

The `design` directory contains some example projects. You can run the transformation process of them with:

```sh
cd design

# build the design
make DESIGN=picorv32 # or any other project

# clean design outputs
make DESIGN=picorv32 clean
```

## Generate FPGA bitstream

In this step you need to create an FPGA design with a vendor tool (e.g. Vivado), using the output design file `emu_system.v` and the following supplementary files:

- Verilog include directories listed by `remu-config --includes`
- Verilog sources listed by `remu-config --plat <platform> --sources`
    - Currently supported platforms are: `sim`, `xilinx`

The output design `emu_system.v` should be instantiated with module `EMU_SYSTEM`. This module has a clock and a reset port, and an AXI-lite interface for emulation control and several AXI interface for memory access. These interfaces should be connected to CPU and FPGA DRAM in the top design.

After the FPGA design is created, run the synthesis & implementation flow and a bitstream for FPGA programming is generated.

## Run emulation

(TODO)

The driver executable `remu-driver` is used to control the execution of FPGA emulation.

## Replay in simulator

(TODO)

Compile simulation executable:

```sh
iverilog $(remu-config --ivl-flags) -s emu_top -o sim.vvp emu_elab.v
```

Run simulation to replay a checkpoint for a specified period of time:

```sh
vvp $(remu-config --vvp-flags) sim.vvp -fst -replay-scanchain sysinfo.json -replay-checkpoint checkpoint +dumpfile=dump.fst +runcycle=1000
```

# Limitations

Currently this framework has the following limitations on user design:

- Escaped identifiers are not allowed.

```verilog
module top;
    reg [3:0] \a.b ; // a.b is an escaped identifier
endmodule
```

- Hierarchical connections are not supported:

```verilog
module top (
    input           clk,
    input   [3:0]   a,
    output  [3:0]   b,
    output  [3:0]   c
);

    sub u_sub (
        .clk    (clk),
        .a      (a),
        .b      (b)
    );

    assign c = u_sub.c; // hierarchical connection

endmodule

module sub (
    input           clk,
    input   [3:0]   a,
    output  [3:0]   b
);

    reg [3:0] c;
    always @(posedge clk) c <= a;
    assign b = ~c;

endmodule
```
