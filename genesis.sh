#!/usr/bin/env bash

# Checks the current operation system and distribution (if applicable), and
# executes the appropriate setup script.

# Ensure this script was not sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "This script must be executed, not sourced!"
    return 1
fi

# Check if we're running as root
if (( EUID != 0 )); then
    echo "This script must be run with root privileges!"
    exit 1
elif [[ -z "${SUDO_USER+x}" ]]; then
    echo "This script must be run via 'sudo' as current user, not as the root user!"
    exit 1
fi

# Get the root directory for genesis
unset CDPATH
genesis_root="$( cd "$( dirname "$0" )" && pwd )"
unset CDPATH

# Run init script
if [ -z ${genesis_init+x} ]; then
    source ""$genesis_root"/init.sh"
fi

# Require power to be connected
if ! hasACConnected; then
    printf "\nAC adapter must be connected to continue executing script!\n"
    #exit 1
fi

# Require an active internet connection
if ! hasActiveInternet; then
    printf "\nNo internet connection detected! Aborting.\n"
    exit 1
fi

# Executes setup scripts
# Returns:
#   0 if a script is executed
function genesisMain() {
    local ret_code=0

    printf "\n>>>>> Begin Genesis System Configuration Script <<<<<\n"

    # Load the correct setup script path, and execute it if successful
    if [ ! -z "${genesis_system_script+x}" ]; then
        printf "\nExecuting selected setup script...\n"

        # Execute the selected setup script
        source "$genesis_system_script"

        # Check if an error occurred during script execution
        if [ ! $? ]; then
            printf "\nSetup script completed with errors!\n"
        fi
    else
        printf "\nNo setup script available for this system!\n"
        ret_code=1
    fi

    printf "\n>>>>> Genesis System Configuration Script Complete <<<<\n"

    return $ret_code
}

# Require reboot if a script was executed
if genesisMain; then
    printf "\nReboot required to complete setup!\n"
    read -p "Press any key to reboot..."
    #reboot
else
    printf "\nSetup Aborted! Failed to execute setup script!\n"
fi
