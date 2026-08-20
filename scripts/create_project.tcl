# Project settings
set project_name "sha256"

# Set project root
set script_dir [file normalize [file dirname [info script]]]
set project_root [file dirname $script_dir]

# Create project and directory structure
set build_dir "$project_root/build"
create_project $project_name $build_dir -force

# Add design sources
set src_dir "$project_root/src"
add_files [glob "$src_dir/*.sv"]

# Add memory initialization files
set mem_dir "$project_root/mem"
add_files [glob "$mem_dir/*.mem"]

# Add simulation sources
set sim_dir "$project_root/sim"
add_files [glob "$sim_dir/*.sv"]