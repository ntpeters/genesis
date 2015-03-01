#!/usr/bin/env bash

# Sets up a new install of Fedora

# Ensure the init script was run
if [ -z "${genesis_init+x}" ]; then
    echo "Genesis init script must be run before this script!"
    exit 1
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

# Perform Fedora configuration
function fedoraMain() {
    local ret_code=0

    printf "\n### Begin Fedora Setup ###\n"

    # Notify the user if we see an Nvidia device, and setup environment params
    if nvidiaGraphics; then
        echo "Nvidia device detected!"
        echo "Getting device driver info..."

        # Get driver info for device
        pyvidia_src="https://raw.githubusercontent.com/ntpeters/pyvidia/master/pyvidia.py"
        pyvidia_dst="/tmp/pyvidia/pyvidia.py"

        download "$pyvidia_src" "$pyvidia_dst" "Pyvidia" ""
        if ! isInstalled "python"; then
            installFromRepo "python"
        fi
        if ! isInstalled "python-beautifulsoup4"; then
            installFromRepo "python-beautifulsoup4"
        fi

        nvidia_driver_version=`python "$pyvidia_dst" --verbose`

        echo "$nvidia_driver_version"
    fi

    # Setup the shell
    source ""$genesis_fedora_scripts"/shell-setup.sh"
    ret_code=$(($ret_code|$?))

    # Perform setup for yum
    source ""$genesis_fedora_scripts"/yum-setup.sh"
    ret_code=$(($ret_code|$?))

    # Update packages
    #runCommand "yum -y update" "Performing Update..."
    echo "Performing system update..."
    yum -y update
    ret_code=$(($ret_code|$?))

    # Setup graphics
    source ""$genesis_fedora_scripts"/nvidia-setup.sh"
    ret_code=$(($ret_code|$?))

    # Fix Fedora's font rendering
    source ""$genesis_fedora_scripts"/fix-fonts.sh"
    ret_code=$(($ret_code|$?))

    # Install packages
    source ""$genesis_fedora_scripts"/install-packages.sh"
    ret_code=$(($ret_code|$?))

    # Install third party programs
    source "$genesis_fedora_scripts/custom-installs.sh"
    ret_code=$(($ret_code|$?))

    # Configure Gnome settings and extensions
    source ""$genesis_fedora_scripts"/gnome-setup.sh"
    ret_code=$(($ret_code|$?))

    # Perform various system tweaks
    source ""$genesis_fedora_scripts"/system-tweaks.sh"
    ret_code=$(($ret_code|$?))

    # Perform additional setup actions
    #source ""$genesis_fedora_scripts"/extra.sh"
    #ret_code=$(($ret_code|$?))

    printf "### Fedora Setup Complete ###\n"

    return $ret_code
}

fedoraMain
return $?
