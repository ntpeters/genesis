#!/usr/bin/env bash

# Installs specified packages

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
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi
if [ -z "${genesis_fedora_install_funcs}" ]; then
    source ""$genesis_fedora_common"/install-funcs.sh"
fi

# Performs package installations
function installPackagesMain() {
    local ret_code=0

    local package_manifest="$genesis_fedora_config/packages.manifest"

    printf "\n### Begin Package Installation ###\n"

    if [ -f "$package_manifest" ]; then
        while read line
        do
            installFromRepo "$line"
            ret_code=$(($ret_code|$?))
        done < "$package_manifest"
    else
        echo "Package manifest not found in config directory!"
        ret_code=1
    fi

    printf "### End Package Installation ###\n\n"
}

installPackagesMain
return $?
