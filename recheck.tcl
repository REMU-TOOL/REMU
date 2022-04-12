set script_dir [file dirname [info script]]

set top {}
set sc_file {}
set ldr_file {}

set opt {}
foreach arg $argv {
    if {$opt == ""} {
        if {[string index $arg 0] == "-"} {
            set opt $arg
        } else {
            puts "${arg}: option expected"
            exit 1
        }
    } else {
        switch $opt {
            -top { set top $arg }
            -sc { set sc_file $arg }
            -ldr { set ldr_file $arg }
            default {
                puts "unrecognized option ${opt}"
                exit 1
            }
        }
        set opt {}
    }
}

set emu_instrument_cmd [list]
if {$sc_file != ""} {
    lappend emu_instrument_cmd -yaml ${sc_file}
}
if {$ldr_file != ""} {
    lappend emu_instrument_cmd -loader ${ldr_file}
}

yosys -import

read_verilog -I ${script_dir}/emulib/include ${script_dir}/emulib/common/*.v ${script_dir}/emulib/fpga/*.v

hierarchy -check -top ${top}
procs
opt_clean
memory_collect
memory_share
check

emu_check
emu_opt_ram
opt_clean
uniquify
hierarchy

emu_handle_directive
emu_instrument {*}$emu_instrument_cmd
emu_package

emu_remove_keep
check
opt
submod
opt
