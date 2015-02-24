#!/usr/bin/env bash

# Performs additional actions unrelated to the other setup scripts

# Check if the init script was run
if [ -z "${genesis_init+x}" ]; then
    echo "Genesis init script must be run before this script!"
    return 1
fi

# Ensure we were sourced
require_sourced

# Ensure we were run as root
require_root

# Require Fedora
require_distribution "Fedora"

# Source function definitions if they haven't been sourced
if [ -z "${genesis_fedora_extra_funcs}" ]; then
    source ""$genesis_fedora_common"/extra-funcs.sh"
fi

# Perform extra actions
function extraMain() {
    local ret_code=0

    printf "\n### Begin Extra Actions ###\n"

    # Build the Vim YouCompleteMe plugin if it exists
    build_ycm_plugin

    printf "\n### End Extra Actions ###\n"

    return $ret_code
}

extraMain
return $?
