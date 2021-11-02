set bd_list {system}
foreach bd $bd_list {
    source ${plat}/scripts/${bd}.tcl
    validate_bd_design
    save_bd_design
    close_bd_design ${bd}
    set_property synth_checkpoint_mode None [get_files ${bd}.bd]
    generate_target all [get_files ${bd}.bd]
    import_files [make_wrapper -files [get_files ${bd}.bd] -top]
}

set_property top system_wrapper [current_fileset]
