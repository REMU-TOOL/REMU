set top {}
set cfg_file {}
set ldr_file {}

set opt {}
foreach arg $argv {
    if {$opt == ""} {
        if {[string index $arg 0] == "-"} {
            set opt $arg
        } else {
            puts ${arg}: option expected
            exit
        }
    } else {
        switch $opt {
            -top { set top $arg }
            -cfg { set cfg_file $arg }
            -ldr { set ldr_file $arg }
            default {
                puts unrecognized option ${opt}
                exit
            }
        }
        set opt {}
    }
}

if {$opt != ""} {
    puts missing parameter for option ${opt}
    exit
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
yosys proc
yosys flatten
yosys wreduce

# recognize byte-write-enable patterns for write ports
yosys memory_share

# run opt_dff to enable recognition of some patterns of synchronous read ports
yosys opt_dff

yosys memory_collect

yosys emu_opt_ram
yosys opt_clean
yosys emu_instrument {*}$emu_instrument_cmd

#yosys opt
