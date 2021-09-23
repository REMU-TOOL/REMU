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

set prep_cmd [list -flatten -rdff]
if {$top != ""} {
    lappend prep_cmd -top ${top}
}

set insert_accessor_cmd [list]
if {$cfg_file != ""} {
    lappend insert_accessor_cmd -cfg ${cfg_file}
}
if {$ldr_file != ""} {
    lappend insert_accessor_cmd -ldr ${ldr_file}
}

yosys prep {*}$prep_cmd
yosys memory_share
yosys insert_accessor {*}$insert_accessor_cmd
yosys opt
