# Provides helper functions for working with Yum repositories

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Source general funcs it it hasn't been sourced
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi

# Checks if a repository is installed
# Input:
#   The name of the repository to check
# Returns:
#   0 if the repo is installed
function repoInstalled() {
    local repo_name="$@"
    local repo_list=`yum repolist all "$repo_name"`

    (echo "$repo_list" | grep --quiet --ignore-case "$repo_name")
    return $?
}

# Checks if a repository is enabled
# Input:
#   The name of the repository to check
# Returns:
#   0 if the repo is enabled
function repoEnabled() {
    local repo_name="$@"
    local repo_list=`yum repolist enabled "$repo_name"`

    (echo "$repo_list" | grep --quiet --ignore-case "$repo_name")
    if [ $? == 0 ]; then
        (echo "$repo_list" | grep --quiet --ignore-case "disabled")
        if [ $? == 1 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Enables a repository if it is not already enabled
# Input:
#   $1 - Name of the repository to enable
function enableRepo() {
    local ret_code=0

    local name="$1"

    if repoInstalled "$name"; then
        if repoEnabled "$name"; then
            echo "Repository '"$name"' already enabled!"
        else
            runCommand "yum-config-manager --enable "$name"" "Enabling '"$name"' repository..."
            ret_code=$(($ret_code|$?))
        fi
    else
        echo "Repository '"$name"' not installed!"
    fi

    return $ret_code
}

# Installs a repository if it is not already installed
# Input:
#   $1 - Name of the repository being installed
#   $2 - Command to install the repository
function installRepo() {
    local ret_code=0

    local name="$1"
    local install="$2"

    if repoInstalled "$name"; then
        echo "Repository '"$name"' already installed!"
    else
        runCommand "$install" "Installing '"$name"' repository..."
        ret_code=$(($ret_code|$?))
    fi

    return $?
}

# Denotes that this file has been sourced
genesis_fedora_repo_funcs=0
