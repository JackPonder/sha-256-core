# Required imports for recursively getting all files in a directory
package require fileutil

# Project settings
set project_name "sha256"
set fpga_part "xc7a35tcpg236-1"
set top_module "top"

# Set project root
set script_dir [file normalize [file dirname [info script]]]
set project_root [file dirname $script_dir]

# Create project and directory structure
set build_dir "$project_root/build"
create_project $project_name $build_dir -part $fpga_part -force

# Add design sources
set src_dir "$project_root/src"
add_files [fileutil::findByPattern $src_dir *.sv]

# Add memory initialization files
set mem_dir "$project_root/mem"
add_files [fileutil::findByPattern $mem_dir *.mem]

# Add constraints
set constr_dir "$project_root/constraints"
add_files -fileset constrs_1 [fileutil::findByPattern $constr_dir *.xdc]

# Add simulation sources
set sim_dir "$project_root/tests"
add_files -fileset sim_1 [fileutil::findByPattern $sim_dir *.sv]
