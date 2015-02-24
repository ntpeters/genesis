#/usr/bin/env bash

# Fixes font rendering

# Check if the init script was run
if [ -z "${genesis_init+x}" ]; then
    echo "Genesis init script must be run before this script!"
    return 1
fi

# Ensure we were sourced
require_sourced

# Ensure we were run as root
require_root

# Require fedora
require_distribution "Fedora"

# Source install funcs if they haven't been
if [ -z "${genesis_fedora_install_funcs}" ]; then
    source ""$genesis_fedora_common"/install-funcs.sh"
fi

# Performs fixes for font rendering
function fixFontsMain() {
    local ret_code=0

    local font_config_src=""$genesis_fedora_assets"/font.conf"
    local font_config_dst="/etc/fonts/local.conf"

    printf "\n### Begin Fix Fonts ###\n"

    # Install a better font renderer
    installPackage "freetype-freeworld"
    ret_code=$(($ret_code|$?))

    # Packages required for Microsoft Fonts
    installPackage "curl"
    ret_code=$(($ret_code|$?))
    installPackage "cabextract"
    ret_code=$(($ret_code|$?))
    installPackage "fontconfig"
    ret_code=$(($ret_code|$?))
    installPackage "xorg-x11-font-utils"
    ret_code=$(($ret_code|$?))

    # Install Microsoft Fonts
    runCommand "rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm" "Installing Microsoft Fonts..."
    ret_code=$(($ret_code|$?))

    if [ -f "$font_config_src" ]; then
        # Copy font config
        runCommand "cp -f "$font_config_src" "$font_config_dst"" "Copying modified font config..."
        ret_code=$(($ret_code|$?))
    else
        echo "Font config not found in assets directory!"
        ret_code=1
    fi

    # Update Gnome font settings
    runCommand "gsettings set org.gnome.settings-daemon.plugins.xsettings hinting slight" "Updating Gnome font hinting setting..."
    ret_code=$(($ret_code|$?))
    runCommand "gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing rgba" "Updating Gname antialiasing setting..."
    ret_code=$(($ret_code|$?))

    # Create the Xresources file with the lcdfilter setting
    runCommand "echo 'Xft.lcdfilter: lcddefault' > "$user_home"/.Xresources" "Enabling LCD Filter..."
    ret_code=$(($ret_code|$?))

    printf "### End Fix Fonts ###\n"

    return $ret_code
}

fixFontsMain
return $?
