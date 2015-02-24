# Perform any needed initialization steps prior to running genesis

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Ensure the genesis_root path is setup before loading the remaining paths
if [ -z "${genesis_root+x}" ]; then
    echo "Variable 'genesis_root' must be set prior to init!"
    return 1
fi

printf "\nInitializing Genesis...\n"

# Setup path variables:
echo "Setting up paths..."

username="$(logname)"

# Home directory for the user running this script
user_home="$(eval echo ~${username})"

# Directory containing genesis configs
genesis_config=""$user_home"/.genesis_config"

# Directory containing configs for the Fedora scripts
genesis_fedora_config=""$genesis_config"/fedora"

# Genesis common scripts
genesis_common=""$genesis_root"/common"

# Fedora main directory
genesis_fedora_root=""$genesis_root"/fedora"

# Fedora setup scripts
genesis_fedora_scripts=""$genesis_fedora_root"/scripts"

# Additional files needed by Fedora scripts
genesis_fedora_assets=""$genesis_fedora_root"/assets"

# Fedora common scripts
genesis_fedora_common=""$genesis_fedora_scripts"/common"

# Source function definitions if they haven't been sourced:
echo "Sourcing common scripts..."
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi
if [ -z "${genesis_script_requires}" ]; then
    source ""$genesis_common"/script-requires.sh"
fi

# Load the path for the correct setup script for this platform
source ""$genesis_common"/select-script.sh"

# Notify the user if we think this is a laptop or not
if isLaptop; then
    echo "Laptop detected!"
else
    echo "This is not a laptop."
fi

# Denotes that this script was sourced
genesis_init=0
