# Provides functions to select the correct setup script to execute for this platform

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Sets the directory to the setup script for the current linux distribution
# Returns:
#   0 if the script directory is set successfully
function selectLinuxDistributionScript() {
    echo "Checking Linux distribution..."

    # Check which distro we're running on using lsb_release
    if commandExists "lsb_release"; then
        local linux_distro=`lsb_release -si`
        case "$linux_distro" in
            Fedora)
                echo "Fedora detected!"
                genesis_system_script="$genesis_fedora_root"
                return 0
                ;;
            Ubuntu)
                echo "Ubuntu support not yet implemented!"
                ;;
            *)
                echo "Unsupported Linux Distribution: "$linux_distro""
                ;;
        esac
    else
        echo "Required command 'lsb_release' not found!"
    fi

    # No script exists for this distribution
    return 1
}

# Sets the directory to the setup script for the current operating system
# Returns:
#   0 if the script directory is set successfully
function selectOSScript() {
    echo "Checking operating system..."

    # Check the OS we're running on
    case "$OSTYPE" in
        linux*)
            echo "Linux detected!"
            selectLinuxDistributionScript
            return $?
            ;;
        darwin*)
            echo "Mac OS X support not yet implemented!"
            ;;
        solaris*)
            echo "Solaris not supported!"
            ;;
        bsd*)
            echo "BSD not supported!"
            ;;
        *)
            echo "Unknown Operating System: "$OSTYPE""
            ;;
    esac

    # No script exists for this OS
    return 1
}

# Sets the path to the correct system setup script
# Returns:
#   0 if the script path is set successfully
function loadSystemScriptPath() {
    # Clear the script variable
    genesis_system_script=""

    # Try to set the directory based on OS
    if selectOSScript; then
        # Check that that script path is set
        if [ -z "${genesis_system_script+x}" ]; then
            return 1
        else
            genesis_system_script=""$genesis_system_script"/main.sh"
            return 0
        fi
    else
        return 1
    fi
}

function selectScriptMain() {
    echo "Selecting setup script for this platform..."
    loadSystemScriptPath
    return $?
}

selectScriptMain
return $?
