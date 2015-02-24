# General use functions

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Displays a progress spinner during execution of a command
# Modified from source: http://fitnr.com/showing-a-bash-spinner.html
# Input
#   $1 - PID of the background process to show progress for
#   $2 - Message to display during execution
function progress() {
    local ret_code=0

    local pid="$1"
    local msg="$2"

    local delay=0.175
    local spinstr='|/-\'

    printf "%s\t" "$msg"

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done

    wait $pid
    ret_code=$(($ret_code|$?))

    printf "\b\b\b[Done]\n"

    return $ret_code
}

# Checks if a program exists
# Input:
#   The program to check for
# Returns:
#   0 if the program exists
function commandExists() {
    local prog="$@"
    if ! prog_loc="$(type -p "$prog")" || [ -z "$prog_loc" ]; then
        return 1
    else
        return 0
    fi
}

# Executes a given command with progress spinner and suppressed output
# Input:
#   $1 - The command to execute
#   $2 - The message to display during execution
function runCommand() {
    local cmd=""$1" > /dev/null 2>&1"
    local msg="$2"
    local ret_code=0

    eval "$cmd" &
    progress $! "$msg"
    ret_code="$?"

    return $ret_code
}

# Executes a command as the given user with progress spinner and suppressed output
# Input:
#   $1 - The command to execute
#   $2 - The message to display during execution
#   $3 - The username of the user to execute as
function runCommandAsUser() {
    local cmd=""$1" > /dev/null 2>&1"
    local msg="$2"
    local user="$3"
    local ret_code=0

    local usercmd="su "$user" -c'"$cmd"'"

    eval "$usercmd" &
    progress $! "$msg"
    ret_code="$?"

    return $ret_code
}

# Executes the given script if it exists
# Input:
#   The path to the script to run
function runScript() {
    local ret_code=0

    local script_path="$@"

    # Ensure the script exists
    if [[ -f "$script_path" ]]; then
        # Ensure the script is executable
        if [[ ! -x "$script_path" ]]; then
            (chmod +x "$script_path" --silent)
        fi

        # Execute the script
        ("$script_path")
        ret_code="$?"
    else
        echo "Script '"$script_path"' does not exist!"
    fi

    return $ret_code
}

# Checks if an Nvidia device is present
# Returns:
#   0 if an Nvidia device is found
function nvidiaGraphics() {
    (lspci | grep --ignore-case "VGA" | grep --quiet --ignore-case --word-regexp "NVIDIA")
    return $?
}

# Downloads a file with a progress bar
# Input:
#   $1 - Link to the download
#   $2 - Path to download the file to
#   $3 - Name of the download file
#   $4 - Additional curl flags (optional)
function download() {
    local ret_code=0

    local link="$1"
    local dest="$2"
    local name="$3"
    local flags="${4:-""}"

    echo "Downloading "$name"..."

    local cmd="curl "$flags" --location "$link" --output "$dest" --progress-bar --create-dirs"
    eval "$cmd"
    ret_code=$(($ret_code|$?))

    # Move to the beginning of the previous line in order to rewrite it
    echo -en "\e[1A"
    echo -e "\e[0K\r"
    echo -en "\e[2A"

    echo "Downloading "$name"... [Done]"

    return $ret_code
}

# Determines if a definition exists for the specified bash function
# Input:
#   $1 - Function name
# Returns:
#   0 if the function exists
function functionExists() {
    declare -f -F $1 > /dev/null
    return $?
}

# Determines if the current device is a laptop
# Returns:
#   0 if the current device is a laptop
function isLaptop() {
    local ret_code=1

    local chassis=`dmidecode --string chassis-type`
    case "$chassis" in
        "Portable")
            ;&
        "Notebook")
            ;&
        "Sub Notebook")
            ;&
        "Laptop")
            ret_code=0
            ;;
    esac

    return $ret_code
}

# Loads the max supported Vesa resolution and hex mode
# into the environment vars:
#   vesa_max_res
#   vesa_max_mode
# Returns:
#   if 1 is returned, 'hwinfo' is not installed
function loadVesaInfo() {
    local ret_code=0

    if commandExists "hwinfo"; then
        local vesa_info=`hwinfo --framebuffer`
        local vesa_max=0
        local vesa_val=0

        while read -r vesa_line; do
            vesa_val=`echo "$vesa_line" | grep -Po '(?<=\(\+).*(?=\))'`
            if [ "$vesa_val" != "" ] && (( $vesa_val > $vesa_max )); then
                vesa_max="$vesa_val"
                vesa_max_mode=`echo "$vesa_line" | grep -Po '(?<=Mode ).*(?=:)'`
                vesa_max_res=`echo "$vesa_line" | grep -Po '(?<=: ).*(?= \()'`
            fi
        done <<< "${vesa_info}"
    else
        ret_code=1
    fi

    return $ret_code
}

# Checks if an SSD exists in this computer
function hasSSD() {
    for disk in `\ls -d /sys/block/sd*`; do
        local rot="$disk/queue/rotational"
        local sched="$disk/queue/scheduler"
        if [[ `cat $rot` -eq 0 ]]; then
            if [[ -w "$sched" ]]; then
                return 0
            fi
        fi
    done

    return 1
}

# Checks if this computer has a battery
function hasBattery() {
    if [ -f /sys/module/battery/initstate ] || [ -d /proc/acpi/battery/BAT0 ] || [ -d /sys/class/power_supply/BAT0 ]; then
        return 0
    else
        return 1
    fi
}

# Checks if the AC adapater is connected
function hasACConnected() {
    if [ -f /sys/class/power_supply/AC/state ] && [[ `cat /sys/class/power_supply/AC/state` = "1" ]]; then
        return 0
    elif [ -f /sys/class/power_supply/AC/online ] && [[ `cat /sys/class/power_supply/AC/online` = "1" ]]; then
        return 0
    else
        return 1
    fi
}

# Checks if there is an active internet connection
function hasActiveInternet() {
    wget -q --tries=10 --timeout=20 --spider http://google.com
    return $?
}

# Checks if any swap devices exist
function hasSwap() {
    grep -qE "(partition|file)" /proc/swaps
    return $?
}

# Backs up a file and adds timestamp to backup filename
# Input:
#   Path to the file to backup
function backupFile() {
    local src="$@"
    local src_path=$(dirname "$src")
    local src_file=$(basename "$src")

    local datetime=`date +%Y-%m-%d--%H:%M:%S`
    local dst_file="["$datetime"]"$src_file".bak"
    local dst=""$src_path"/"$dst_file""

    cp "$src" "$dst"
    return $?
}

# Denotes that this file has been sourced
genesis_general_funcs=0
