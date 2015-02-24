#!/usr/bin/env bash

# Configures yum

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
if [ -z "${genesis_fedora_install_funcs}" ]; then
    source ""$genesis_fedora_common"/install-funcs.sh"
fi
if [ -z "${genesis_fedora_custom_install_funcs}" ]; then
    source ""$genesis_fedora_common"/custom-install-funcs.sh"
fi
if [ -z "${genesis_fedora_system_funcs}" ]; then
    source ""$genesis_fedora_common"/system-funcs.sh"
fi
if [ -z "${genesis_fedora_repo_funcs}" ]; then
    source ""$genesis_fedora_common"/repo-funcs.sh"
fi

# Perform Yum setup
function yumSetupMain() {
    local ret_code=0

    printf "\n### Begin Yum Setup ###\n"

    # Install the axelget plugin to speed up yum downloads
    installPackage "yum-axelget"
    ret_code=$(($ret_code|$?))

    # Set yum to update metadata in the background
    enableService "yum-updatesd"
    ret_code=$(($ret_code|$?))

    # Set yum to keep cache updated in the background
    enableService "yum-makecache.timer"
    ret_code=$(($ret_code|$?))

    # Update yum config
    local yum_conf_file="/etc/yum.conf"
    local save_yum_conf=" > ""$yum_conf_file".tmp" && mv ""$yum_conf_file".tmp" "$yum_conf_file""
    local yum_conf=`cat "$yum_conf_file"`

    # Make yum keep downloaded caches
    if [[ "$yum_conf" != *"keepcache"* ]]; then
        echo "keepcache=1" >> "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum keepcache enabled"
    elif [[ "$yum_conf" != *"keepcache=1"* ]]; then
        sed -i -e 's/keepcache=0/keepcache=1/g' "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum keepcache enabled"
    else
        echo "Yum keepcache already enabled"
    fi

    # Enable coloring of yum
    if [[ "$yum_conf" != *"color"* ]]; then
        echo "color=always" >> "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum color mode enabled"
    elif [[ "$yum_conf" = *"color=never"* ]]; then
        sed -i -e 's/color=never/color=always/g' "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum color mode enabled"
    elif [[ "$yum_conf" = *"color=auto"* ]]; then
        sed -i -e 's/color=auto/color=always/g' "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum color mode enabled"
    else
        echo "Yum color mode already enabled"
    fi

    # Tell yum to cleanup unused dependencies of a package when it is removed or updated
    if [[ "$yum_conf" != *"clean_requirements_on_remove"* ]]; then
        echo "clean_requirements_on_remove=1" >> "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum requirement cleaning enabled"
    elif [[ "$yum_conf" != *"clean_requirements_on_remove=1"* ]]; then
        sed -i -e 's/clean_requirements_on_remove=0/clean_requirements_on_remove=1/g' "$yum_conf_file"
        ret_code=$(($ret_code|$?))
        echo "Yum requirement cleaning enabled"
    else
        echo "Yum requirement cleaning already enabled"
    fi

    # Setup yum repositories
    customInstall "repo-rpmfusion"
    ret_code=$(($ret_code|$?))
    customInstall "repo-flash-plugin"
    ret_code=$(($ret_code|$?))
    customInstall "repo-skype"
    ret_code=$(($ret_code|$?))
    customInstall "repo-handbrake"
    ret_code=$(($ret_code|$?))
    customInstall "repo-cdrtools"
    ret_code=$(($ret_code|$?))
    customInstall "repo-numix-themes"
    ret_code=$(($ret_code|$?))
    customInstall "repo-hwinfo"
    ret_code=$(($ret_code|$?))
    customInstall "repo-nvidia"
    ret_code=$(($ret_code|$?))

    # Re-make yums metadata cache
    runCommand "yum makecache" "Rebuilding yum cache..."
    ret_code=$(($ret_code|$?))

    printf "### End Yum Setup ###\n\n"

    return $ret_code
}

yumSetupMain
return $?
