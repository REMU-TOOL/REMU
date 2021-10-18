set top {}
set cfg_file {}
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
            -cfg { set cfg_file $arg }
            -ldr { set ldr_file $arg }
            default {
                puts "unrecognized option ${opt}"
                exit 1
            }
        }
        set opt {}
    }
}

if {$opt != ""} {
    puts "missing parameter for option ${opt}"
    exit 1
}

set hierarchy_cmd [list -check]
if {$top != ""} {
    lappend hierarchy_cmd -top ${top}
} else {
    lappend hierarchy_cmd -auto-top
}

set emu_instrument_cmd [list]
if {$cfg_file != ""} {
    lappend emu_instrument_cmd -cfg ${cfg_file}
}
if {$ldr_file != ""} {
    lappend emu_instrument_cmd -ldr ${ldr_file}
}

yosys hierarchy {*}$hierarchy_cmd
yosys emu_keep_top
yosys proc
yosys flatten
yosys opt
yosys wreduce
yosys memory_share
yosys memory_collect
yosys opt -fast
yosys check

yosys emu_lint
yosys emu_opt_ram
yosys opt_clean
yosys emu_instrument {*}$emu_instrument_cmd
yosys check

yosys opt
