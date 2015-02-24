#!/usr/bin/env bash

# Sets up the shell

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
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general_funcs.sh"
fi
if [ -z "${genesis_fedora_system_funcs}" ]; then
    source ""$genesis_fedora_common"/system-funcs.sh"
fi
if [ -z "${genesis_fedora_install_funcs}" ]; then
    source ""$genesis_fedora_common"/install-funcs.sh"
fi

# Performs setup for the shell
function shellSetupMain() {
    local ret_code=0

    printf "\n### Begin Shell Configuration ###\n"

    printf "\n"

    local sysconf_network="/etc/sysconfig/network"
    local hosts="/etc/hosts"
    local hostfile="/etc/hostname"

    local cur_hostname_file=$(cat "$hostfile")
    local cur_hostname_cmd=$(hostname)

    # Promp user for new hostname
    echo "Setting new hostname..."
    echo "Current hostname: "$cur_hostname_cmd" ("$cur_hostname_file")"
    read -p "New Hostname: " new_hostname
    if [[ "$new_hostname" != "$(hostname)" ]]; then
        if [ -f "$sysconf_network" ]; then
            if [[ "$sysconf_network" = *"$cur_hostname_file"* ]]; then
                sed -i -e 's/"$cur_hostname_file"/"$new_hostname"'
            elif [[ "$sysconf_network" = *"$cur_hostname_cmd"* ]]; then
                sed -i -e 's/"$cur_hostname_cmd"/"$new_hostname"'
            else
                echo "HOSTNAME="$new_hostname"" >> "$sysconf_network"
            fi
        fi
        if [ -f "$hostfile" ]; then
            echo "$new_hostname" > "/tmp/hostname"
            cp -f "/tmp/hostname" "$hostfile"
        fi
        hostname --boot "$new_hostname"
        if [ $? -eq 0 ]; then
            echo "Hostname set to: "$(hostname)""
        else
            echo "Failed to update hostname!"
        fi
    else
        echo "New hostname is the same as the current hostname!"
    fi

    printf "\n"

    # Prompt user for desired shell
    echo "Setting default shell..."
    local shells="/tmp/shells"
    local shell_names="/tmp/shell-names"
    while [[ 1 ]]
    do
        chsh --list-shells | grep /usr/ | grep --invert-match nologin > "$shells"
        cat "$shells" | cut -d '/' -f 4 > "$shell_names"

        printf "Available Shells:\n"
        cat -n "$shell_names"
        local lines=$(wc -l "$shells" | cut -d ' ' -f 1)
        printf "     %d  Install Other Shell\n" $(($lines+1))
        read -p "Select Option: " choice
        case $choice in
           [0-9])
                if (( $choice > 0 && $choice <= $lines )); then
                    chosen_shell=$(sed -n "$choice"p "$shells")
                    chsh --shell "$chosen_shell" "$username"
                    break
                elif [ $choice -eq $(($lines+1)) ]; then
                    read -p "Name of other shell: " other_shell
                    installFromRepo "$other_shell"
                else
                    echo "Invalid Option!"
                fi
                ;;
            *)
                echo "Invalid Option!"
                ;;
        esac
    done

    printf "\n### End Shell Configuration ###\n"

    return $ret_code
}

shellSetupMain
return $?
