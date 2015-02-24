# Provides additional functions for extra actions script

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Source function definitions if they haven't been sourced
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi
if [ -z "${genesis_fedora_install_funcs}" ]; then
    source ""$genesis_fedora_common"/install-funcs.sh"
fi

# Builds the YouCompleteMe Vim plugin
function build_ycm_plugin() {
    local ret_code=0

    echo "Building 'You Complete Me' Vim plugin..."

    local ycm_script_path=""$user_home"/.vim/bundle/YouCompleteMe/install.sh"

    #Check if YCM exists
    if [ ! -f "$ycm_script_path" ]; then
        echo "YCM not installed! Skipping build..."
        return 0
    fi

    # Ensure all required packages are installed for compiling the YCM Vim plugin
    if ! isInstalled clang; then
        installPackage clang
        ret_code=$(($ret_code|$?))
    fi
    if ! isInstalled clang-devel; then
        installPackage clang-devel
        ret_code=$(($ret_code|$?))
    fi
    if ! isInstalled mono-addins-devel; then
        installPackage mono-addins-devel
        ret_code=$(($ret_code|$?))
    fi
    if ! isInstalled python-devel; then
        installPackage python-devel
        ret_code=$(($ret_code|$?))
    fi

    # Excute the YRCM build script
    $ycm_script_path --clang-completer --omnisharp-completer
    ret_code=$(($ret_code|$?))

    echo "You Complete Me build complete!"

    return $ret_code
}

# Denotes that this file has been sourced
genesis_fedora_extra_funcs=0
