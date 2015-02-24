# Functions to limit script executions

# Require a script to be run as root
function require_root() {
    if (( EUID != 0 )); then
        echo "This script must be run as root!"
        exit 1
    fi
}

# Require a script to be sourced
function require_sourced() {
    if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
        echo "This script must be sourced, not executed!"
        exit 1
    fi
}

# Require a script to be run on a specific operating system
function require_os() {
    local required_os="${1,,}"
    local current_os="${OSTYPE,,}"

    if [[ "$current_os" != *"$required_os"* ]]; then
        echo "This script must be run on a "$required_os" platform!"
        exit 1
    fi

    return 0
}

# Require a script to be run on a specific linux distribution
function require_distribution() {
    local required_platform="${1,,}"

    # Ensure this function is only run on linux
    require_os "linux"

    # Load the current distro
    local current_platform=`lsb_release -si`
    current_platform="${current_platform,,}"

    echo Current: "$current_platform"
    echo Require: "$required_platform"

    if [[ "$current_platform" != *"$required_platform"* ]]; then
        echo "This script is intended for "$required_platform" only!"
        exit 1
    fi

    return 0
}

# Denotest that this script has been sourced
genesis_script_requires=0
