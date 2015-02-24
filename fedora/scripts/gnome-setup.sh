#!/usr/bin/env bash

# Configures GNOME

# Check if the init script was run
if [ -z "${genesis_init+x}" ]; then
    echo "Genesis init script must be run before this script!"
    exit 1
fi

#Ensure we were sourced
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
if [ -z "${genesis_fedora_gnome_funcs}" ]; then
    source ""$genesis_fedora_common"/gnome-funcs.sh"
fi

# Perform GNOME setup
# TODO: Complete implementation
function gnomeSetupMain() {
    local ret_code=0

    # Get current username
    local username=$(logname)

    local extension_id_manifest="$genesis_fedora_config/gnome-extension-ids.manifest"
    local extension_url_manifest="$genesis_fedora_config/gnome-extension-urls.manifest"
    local extension_req_manifest="$genesis_fedora_config/gnome-extension-requirements.manifest"

    printf "\n### Begin Gnome Setup ###\n"

    # Install Numix theme
    installPackage "numix-gtk-theme"
    ret_code=$(($ret_code|$?))
    installPackage "numix-icon-theme-circle"
    ret_code=$(($ret_code|$?))

    printf "\n"

    # Install Gnome extensions by ID from extensions.gnome.org
    if [ -f "$extension_id_manifest" ]; then
        # Install and enable shell extensions
        while read line; do
            installGnomeExtensionByID "$line"
            ret_code=$(($ret_code|$?))
        done < "$extension_id_manifest"
    else
        echo "GNOME Extension ID manifest not found in config directory!"
        ret_code=1
    fi

    # Install Gnome extensions not located at extensions.gnome.org
    if [ -f "$extension_url_manifest" ]; then
        while read line; do
            local name=`\echo "$line" | tr -s ' ' | cut -d ' ' -f1`
            local uuid=`\echo "$line" | tr -s ' ' | cut -d ' ' -f2`
            local link=`\echo "$line" | tr -s ' ' | cut -d ' ' -f3`
            installGnomeExtensionFromRemoteZip "$link" "$uuid" "$name"
            ret_code=$(($ret_code|$?))
        done < "$extension_url_manifest"
    else
        echo "GNOME Extension URL manifest not found in config directory!"
        ret_code=1
    fi

    printf "\n"

    # Fullfil extension requirements
    if [ -f "$extension_req_manifest" ]; then
        while read line; do
            local uuid=`\echo "$line" | cut -d '=' -f1`
            local reqs=`\echo "$line" | cut -d '=' -f2`

            if extensionIsInstalled "$uuid"; then
                echo "Installing requirements for extension '"$uuid"'..."
                for req in $reqs; do
                    installFromRepo "$req"
                    ret_code=$(($ret_code|$?))
                done
            fi
        done < "$extension_req_manifest"
    else
        echo "GNOME Extension requirements manifest not found in config directory!"
        ret_code=1
    fi

    printf "\n"

    # Setup themes
    setGnomeThemes
    ret_code=$(($ret_code|$?))

    printf "### End Gnome Setup ###\n"

    return $ret_code
}

gnomeSetupMain
return $?
