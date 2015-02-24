# Provides helper functions from working with GNOME extensions and settings

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Source general funcs if it hasn't been sourced
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi


# Enables a GNOME extension
# Input:
#   $1 - UUID of the extension
#   $2 - The name of the extension
function enableGnomeExtension() {
    local ret_code=0

    local extensionUUID="$1"
    local extensionName="$2"

    # Get list of enabled extensions
    local extensionList=$(su $username -c "gsettings get org.gnome.shell enabled-extensions" | sed 's/^.\(.*\).$/\1/')

    #Check if extension is already enabled
    local extensionEnabled=$(echo $extensionList | grep $(extensionUUID))

    # Enable extension if needed
    if [ "$extensionEnabled" = "" ]; then
        local enabledExtensionCmd="\"gsettings set org.gnome.shell enabled-extensions \\\"["$extensionList", '$extensionUUID']\\\"\""
        eval "su $username -c "$enableExtensionCmd""
        ret_code=$(($ret_code|$?))

        echo "Enabled extension '"$extensionName"'!"
    else
        echo "Extension '"$extensionname"' already enabled!"
    fi

    return $ret_code
}

# Checks if a given extension is already installed
function extensionIsInstalled() {
    local extensionUUID="$1"

    local userExtensionPath="/home/"$username"/.local/share/gnome-shell/extensions"
    local systemExtensionPath="/usr/share/gnome-shell/extensions"

    if [[ -d ""$userExtensionPath"/"$extensionUUID"" || -d ""$systemExtensionPath"/"$extensionUUID"" ]]; then
        return 0
    else
        return 1
    fi
}

# Installs a GNOME extension from a local zip file
# Input:
#   $1 - Path to the extension zip file
#   $2 - UUID of the extension
#   $3 - Name of the extension
function installGnomeExtensionFromLocalZip() {
    local ret_code=0

    local extensionZipPath="$1"
    local extensionUUID="$2"
    local extensionName="$3"

    # Installation path is in user home directory
    local extensionPath="/home/"$username"/.local/share/gnome-shell/extensions"

    if ! extensionIsInstalled "$extensionUUID"; then
        # Unzip extension to installation folder
        mkdir -p ""$extensionPath"/"$extensionUUID""
        ret_code=$(($ret_code|$?))
        unzip -o -q "$extensionZipPath" -d ""$extensionPath"/"$extensionUUID""
        ret_code=$(($ret_code|$?))

        # Ensure proper ownership and permissions
        chown "$username" -R ""$extensionPath"/"$extensionUUID""
        ret_code=$(($ret_code|$?))
        chmod 775 -R ""$extensionPath"/"$extensionUUID""
        ret_code=$(($ret_code|$?))

        echo "Installed extension '"$extensionName"'!"

        # Ensure the extension is enabled
        enableGnomeExtension "$extensionUUID"
    else
        echo "Extension '"$extensionName"' already installed!"
    fi

    return $ret_code
}

# Installs a GNOME extension from a remote zip file
# Input:
#   $1 - Link to the remote zip file
#   $2 - UUID of the extension
#   $3 - Name of the extension
function installGnomeExtensionFromRemoteZip() {
    local ret_code=0

    local extensionLink="$1"
    local extensionUUID="$2"
    local extensionName="$3"
    local dl_dest="/tmp/extension.zip"
    local dl_flags=""

    if ! extensionIsInstalled "$extensionUUID"; then
        # Download the extension zip
        download "$extensionLink" "$dl_dest" "$extensionName" "$dl_flags"
        ret_code=$(($ret_code|$?))

        # Install the extension
        installGnomeExtensionFromLocalZip "$dl_dest" "$extensionUUID" "$extensionName"
        ret_code=$(($ret_code|$?))

        # Cleanup temp files
        rm -f "$dl_dest"
        ret_code=$(($ret_code|$?))
    else
        echo "Extension '"$extensionName"' already installed!"
    fi

    return $ret_code
}

# Installs a GNOME extension from the GNOME extensions site
# Inspired by: http://bernaerts.dyndns.org/linux/76-gnome/283-gnome-shell-install-extension-command-line-script
# Input:
#   $1 - ID of the extension on the site to install
function installGnomeExtensionByID() {
    local ret_code=0

    local extensionID="$1"
    local gnomeSite="https://extensions.gnome.org"
    local gnomeVersion=$(gnome-session --version | cut -d ' ' -f2 | cut -d '.' -f 1,2)

    # Get extension description
    local extensionDescPath="/tmp/extension.txt"
    wget -O "$extensionDescPath" ""$gnomeSite"/extension-info/?pk="$extensionID"&shell_version="$gnomeVersion"" > /dev/null 2>&1
    ret_code=$(($ret_code|$?))

    # Get extension UUID
    local extensionUUID=$(cat "$extensionDescPath" | grep "uuid" | sed 's/^.*uuid[\": ]*\([^\"]*\).*$/\1/')

    # Get extension name
    local extensionName=$(cat "$extensionDescPath" | grep "name" | sed 's/^.*name[\": ]*\([^\"]*\).*$/\1/')

    # Get extension download URL
    local extensionURL=$(cat "$extensionDescPath" | grep "download_url" | sed 's/^.*download_url[\": ]*\([^\"]*\).*$/\1/')

    # Install extension if available
    if [ "$extensionURL" != "" ]; then
        installGnomeExtensionFromRemoteZip "${gnomeSite}${extensionURL}" "$extensionUUID" "$extensionName"
        ret_code=$(($ret_code|$?))
    else
        # Extension is not available
        echo "Extension '"$extensionName"' is not available for GNOME Shell "$gnomeVersion"!"
    fi

    # Remove temp files
    rm -f "$extensionDescPath"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Sets GNOME themes (GTK, Window, Icon, Shell, Cursor)
function setGnomeThemes() {
    local ret_code=0

    local themes_config=""$genesis_fedora_config"/gnome-themes.conf"
    if [ -f "$themes_config" ]; then
        source "$themes_config"
    else
        echo "GNOME themes config not found in config directory!"
        return 1
    fi

    local gtk_theme="$GNOME_GTK_THEME"
    local window_theme="$GNOME_WINDOW_THEME"
    local icon_theme="$GNOME_ICON_THEME"
    local shell_theme="$GNOME_SHELL_THEME"
    local cursor_theme="$GNOME_CURSOR_THEME"

    if [ ! -z "${GNOME_GTK_THEME+x}" ]; then
        local gtk_theme_cmd="gsettings set org.gnome.desktop.interface gtk-theme \""$GNOME_GTK_THEME"\""
        runCommandAsUser "$gtk_theme_cmd" "Setting GTK Theme to "$GNOME_GTK_THEME"..." "$username"
        ret_code=$(($ret_code|$?))
    else
        echo "No setting found for GNOME GTK+ theme! Leaving default."
    fi

    if [ ! -z "${GNOME_WINDOW_THEME+x}" ]; then
        local window_theme_cmd="gsettings set org.gnome.desktop.wm.preferences theme \""$GNOME_WINDOW_THEME"\""
        runCommandAsUser "$window_theme_cmd" "Setting Window Theme to "$GNOME_WINDOW_THEME"..." "$username"
        ret_code=$(($ret_code|$?))
    else
        echo "No setting found for GNOME window theme! Leaving default."
    fi

    if [ ! -z "${GNOME_ICON_THEME+x}" ]; then
        local icon_theme_cmd="gsettings set org.gnome.desktop.interface icon-theme \""$GNOME_ICON_THEME"\""
        runCommandAsUser "$icon_theme_cmd" "Setting Icon Theme to "$GNOME_ICON_THEME"..." "$username"
        ret_code=$(($ret_code|$?))
    else
        echo "No setting found for GNOME icon theme! Leaving default."
    fi

    if [ ! -z "${GNOME_SHELL_THEME+x}" ]; then
        local shell_theme_cmd="gsettings set org.gnome.shell.extensions.user-theme name \""$GNOME_SHELL_THEME"\""
        runCommandAsUser "$shell_theme_cmd" "Setting Shell Theme to "$GNOME_SHELL_THEME"..." "$username"
        ret_code=$(($ret_code|$?))
    else
        echo "No setting found for GNOME shell theme! Leaving default."
    fi

    if [ ! -z "${GNOME_CURSOR_THEME+x}" ]; then
        local cursor_theme_cmd="gsettings set org.gnome.desktop.interface cursor-theme \""$GNOME_CURSOR_THEME"\""
        runCommandAsUser "$cursor_theme_cmd" "Setting Cursor Theme to "$GNOME_CURSOR_THEME"..." "$username"
        ret_code=$(($ret_code|$?))
    else
        echo "No setting found for GNOME cursor theme! Leaving default."
    fi

    local user_theme_ext="gnome-shell-extension-user-theme.noarch"
    if isPackageInstalled "$user_theme_ext"; then
        installPackage "$user_theme_ext"
        ret_code=$(($ret_code|$?))
    else
        echo "No setting found for GNOME cursor theme! Leaving default."
    fi

    local user_theme_ext="gnome-shell-extension-user-theme.noarch"
    if isPackageInstalled "$user_theme_ext"; then
        installPackage "$user_theme_ext"
        ret_code=$(($ret_code|$?))
    fi

    echo "[Settings]
    gtk-application-prefer-dark-theme=1" > "$user_home/.config/gtk-3.0/settings.ini"
    ret_code=$(($ret_code|$?))
    printf "Global Dark Theme Enabled!\n"

    return $ret_code
}

# Denotes that this file has been sourced
genesis_fedora_gnome_funcs=0
