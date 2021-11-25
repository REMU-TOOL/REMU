if { $argc != 2 } {
    puts "ERROR: wrong arguments"
    exit 1
}

set plat    [lindex $argv 0]
set design  [lindex $argv 1]

set design_dir ../../design/build/${design}

source ${plat}/scripts/board.tcl

create_project "${plat}-${design}" -force -dir ${design_dir}/vivado_prj -part ${device}
set_property board_part ${board} [current_project]

add_files -norecurse ${design_dir}/
add_files ../../rtl/
add_files common/rtl/

source ${plat}/scripts/setup.tcl

synth_design -top [get_property top [current_fileset]] -part ${device} -directive RuntimeOptimized

write_checkpoint -force ${design_dir}/vivado_out/synth.dcp

opt_design -directive RuntimeOptimized
place_design -directive RuntimeOptimized
route_design -directive RuntimeOptimized

write_checkpoint -force ${design_dir}/vivado_out/route.dcp

set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
if { ${WNS} < 0.000 } {
    puts "ERROR: Timing constraints failed (WNS=${WNS})"
    exit 1
}

write_bitstream -force ${design_dir}/system.bit
write_cfgmem -format BIN -interface SMAPx32 -disablebitswap \
    -loadbit "up 0x0 ${design_dir}/system.bit" -force ${design_dir}/system.bit.bin
