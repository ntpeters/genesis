#!/usr/bin/env bash

# Tweaks system settings and configs

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
if [ -z "${genesis_fedora_system_funcs}" ]; then
    source ""$genesis_fedora_common"/system-funcs.sh"
fi

# Perform system tweaks
function systemTweaksMain() {
    local ret_code=0

    printf "\n### Begin System Tweaks ###\n"

    configureSELinux
    ret_code=$(($ret_code|$?))

    update_fstab
    ret_code=$(($ret_code|$?))
    setIOSchedulers
    ret_code=$(($ret_code|$?))
    update_sysctl
    ret_code=$(($ret_code|$?))
    enableKSM
    ret_code=$(($ret_code|$?))
    enablePSD
    ret_code=$(($ret_code|$?))
    update_grub
    ret_code=$(($ret_code|$?))

    if isLaptop; then
        echo "Setting up TLP..."
        installFromRepo "tlp"
        ret_code=$(($ret_code|$?))
        enableService "tlp"
        ret_code=$(($ret_code|$?))
        enableService "tlp-sleep"
        ret_code=$(($ret_code|$?))
    fi

    installFromRepo "preload"
    ret_code=$(($ret_code|$?))

    enableService "libvirtd"

    printf "### End System Tweaks ###\n"

    return $ret_code
}

systemTweaksMain
return $?
