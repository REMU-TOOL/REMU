yosys plugin -i transform

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

yosys read_verilog -I ${script_dir}/emulib/include ${script_dir}/emulib/common/*.v ${script_dir}/emulib/fpga/*.v

yosys hierarchy -check -top ${top} -purge_lib
yosys proc
yosys opt_clean
yosys memory_collect
yosys memory_share -nowiden
yosys check

yosys emu_check
yosys emu_opt_ram
yosys opt_clean
yosys uniquify
yosys hierarchy

yosys emu_handle_directive
yosys emu_instrument {*}$emu_instrument_cmd
yosys emu_package

yosys emu_remove_keep
yosys check
yosys opt
yosys submod
yosys opt
