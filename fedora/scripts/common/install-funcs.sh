# Provides helper functions for working with packages and groups

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Source general funcs if it hasn't been sourced
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi

# Checks if a package is installed
# Input:
#   $1 - The name of the package to check for
# Returns:
#   0 if the package was found
function isPackageInstalled() {
    local package="$@"
    local cmd="yum list installed \""$package"\" > /dev/null 2>&1"
    eval "$cmd"
    if [ $? == 0 ]; then
        return 0
    else
        return 1
    fi
}

# Checks if a package is available
# Input:
#   $1 - The name of the package to check for
# Returns:
#   0 if the package was found
function isPackageAvailable() {
    local package="$@"
    local cmd="yum list available \""$package"\" > /dev/null 2>&1"
    eval "$cmd"
    if [ $? == 0 ]; then
        return 0
    else
        return 1
    fi
}

# Checks if a group is installed
# Input:
#   $1 - The name of the group to check for
# Returns:
#   0 if the group was found
function isGroupInstalled() {
    local group="$@"
    local cmd="yum groups list hidden installed \""$group"\""
    eval "$cmd" > /dev/null 2>&1
    if [ $? == 0 ]; then
        local check=""$cmd" | grep -i \""${group:1}"\""
        eval "$check" > /dev/null 2>&1
        if [ $? == 0 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}


# Checks if a group is available
# Input:
#   $1 - The name of the group to check for
# Returns:
#   0 if the group was found
function isGroupAvailable() {
    local group="$@"
    local cmd="yum groups list hidden available \""$group"\""
    eval "$cmd" > /dev/null 2>&1
    if [ $? == 0 ]; then
        local check=""$cmd" | grep -i \""${group:1}"\""
        eval "$check" > /dev/null 2>&1
        if [ $? == 0 ]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Determines if a specified name is a group
# Input:
#   $1 - Name to check
# Returns:
#   0 if it is a group
function isGroup() {
    local name="$@"

    if [[ ${name:0:1} == "@" ]]; then
        return 0
    else
        return 1
    fi
}

# Checks if a given package or group is installed
# Input:
#   $1 - Name of package or group to check for
# Returns:
#   0 if the item is installed
function isInstalled() {
    local ret_code=0

    local package="$@"

    if isGroup "$package"; then
        isGroupInstalled "$package"
        ret_code=$(($ret_code|$?))
    else
        isPackageInstalled "$package"
        ret_code=$(($ret_code|$?))
    fi

    return $ret_code
}

# Checks if a given package or group is available
# Input:
#   $1 - Name of the package or group to check for
# Returns:
#   0 if the item is available
function isAvailable() {
    local ret_code=0

    local package="$@"

    if isGroup "$package"; then
        isGroupAvailable "$package"
        ret_code=$(($ret_code|$?))
    else
        isPackageAvailable "$package"
        ret_code=$(($ret_code|$?))
    fi

    return $ret_code
}

# Installs a package if it is available and not already installed
# Input:
#   $1 - The package to install
function installPackage() {
    local ret_code=0

    local package="$@"

    if isPackageInstalled "$package"; then
        echo "Package '"$package"' is already installed!"
    else
        if isPackageAvailable "$package"; then
            local cmd="yum -y install "$package" > /dev/null 2>&1"
            eval "$cmd" &
            progress $! "Installing package '"$package"'..."
            ret_code=$(($ret_code|$?))
        else
            echo "No package '"$package"' available!"
        fi
    fi

    return $ret_code
}

# Installs a group if it is available and not already installed
# Input:
#   $1 - The group to install
function installGroup() {
    local ret_code=0

    local group="$@"

    if isGroupInstalled "$group"; then
        echo "Group '"$group"' is already installed!"
    else
        if isGroupAvailable "$group"; then
            local cmd="yum -y groups install "$group" > /dev/null 2>&1"
            eval "$cmd" &
            progress $! "Installing group '"$group"'..."
            ret_code=$(($ret_code|$?))
        else
            echo "No group '"$group"' available!"
        fi
    fi

    return $ret_code
}

# Installs a package or group from a configured repository
# Input:
#   $1 - The name of the package or group to install
function installFromRepo() {
    local ret_code=0

    local name="$@"

    if isGroup "$name"; then
        installGroup "$name"
        ret_code=$(($ret_code|$?))
    else
        installPackage "$name"
        ret_code=$(($ret_code|$?))
    fi

    return $ret_code
}

# Installs a package from a local RPM
# Input:
#   $1 - Path to the RPM to install
#   $2 - Name of the package being installed
function installFromLocal() {
    local ret_code=0

    local rpm_path="$1"
    local name="$2"
    local cmd="yum -y localinstall "$rpm_path""

    if [[ -f "$rpm_path" ]]; then
        eval "$cmd" > /dev/null 2>&1 &
        progress $! "Installing '""$name""'..."
        ret_code=$(($ret_code|$?))
    else
        echo "Specified RPM not found: "$rpm_path""
    fi

    return $ret_code
}

# Downloads and extracts an archive
# Input:
#   $1 - Name of the item being installed
#   $2 - Link to the archive to download
#   $3 - Path to download the archive to
#   $4 - Command to unpack the archive
function installRemoteArchive() {
    local ret_code=0

    local name="$1"
    local dl_link="$2"
    local dl_path="$3"
    local unpack_cmd="$4"

    download "$dl_link" "$dl_path" "$name" ""
    ret_code=$(($ret_code|$?))

    local msg="Installing '"$name"'..."
    runCommand "$unpack_cmd" "$msg"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Downloads and installs a zip file
# Input:
#   $1 - Name of the item being installed
#   $2 - Link to the zip to download
#   $3 - Path to extract the zip to
#   $4 - Additional flags to 'unzip' (optional)
function installRemoteZip() {
    local name="$1"
    local dl_link="$2"
    local install_path="$3"
    local tar_flags=${4:-""}
    local filename="${dl_link##*/}"
    local dl_path="/tmp/"$filename""
    local unpack_cmd="unzip -o -q "$dl_path" -d "$install_path""

    mkdir -p "$install_path"
    installRemoteArchive "$name" "$dl_link" "$dl_path" "$unpack_cmd"
    return $?
}

# Downloads and installs a tarball
# Input:
#   $1 - Name of the item being installed
#   $2 - Link to the tarball to download
#   $3 - Path to extract the tarball to
#   $4 - Additional flags to 'tar' (optiojal)
function installRemoteTarball() {
    local name="$1"
    local dl_link="$2"
    local install_path="$3"
    local tar_flags=${4:-""}
    local filename="${dl_link##*/}"
    local dl_path="/tmp/"$filename""
    local unpack_cmd="tar -jxf "$dl_path" -C"$install_path" "$tar_flags""

    mkdir -p "$install_path"
    installRemoteArchive "$name" "$dl_link" "$dl_path" "$unpack_cmd"
    return $?
}

# Executes a custom install function
# Input;
#   $1 - Name of the item to install
function customInstall() {
    local ret_code=0

    local install_name="$1"
    local function_name="install-"$install_name""

    if functionExists "$function_name"; then
        eval "$function_name"
        ret_code=$(($ret_code|$?))
    else
        echo "No install definition for '"$install_name"'!"
    fi

    return $ret_code
}

# Denotes that this file has been sourced
genesis_fedora_install_funcs=0
