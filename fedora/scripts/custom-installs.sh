#!/usr/bin/env bash

# Performs custom installations

# Check if the init script was run
if [ -z "${genesis_init+x}" ]; then
    echo "Genesis init script must be run before this script!"
    return 1
fi

# Ensure we were sourced
require_sourced

# Ensure we were run as root
require_root

# Require fedora
require_distribution "Fedora"

# Source install funcs if they haven't been already
if [ -z "${genesis_fedora_custom_install_funcs}" ]; then
    source ""$genesis_fedora_common"/custom-install-funcs.sh"
fi

# Execute custom installations
function customInstallMain() {
    local ret_code=0

    local install_manifest=""$genesis_fedora_config"/custom-installs.manifest"

    printf "\n### Begin Custom Installations ###\n\n"

    # Ensure the manifest file exists
    if [[ -f "$install_manifest" ]]; then
        # Process each entry in the manifest
        while read line
        do
            customInstall "$line"
            ret_code=$(($ret_code|$?))
            printf "\n"
        done < "$install_manifest"
    else
        echo "Custom install manifest not found in config directory!"
        ret_code=1
    fi

    printf "\n### End Custom Installations ###\n"

    return $ret_code
}

customInstallMain
return $?
