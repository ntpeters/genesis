#!/usr/bin/env bash

# Sets up Nvidia graphics, including GRUB and restoring Plymouth

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
if [ -z "${genesis_fedora_install_funcs}" ]; then
    source ""$genesis_fedora_common"/install-funcs.sh"
fi

# Perform Nvidia setup
function nvidiaSetupMain() {
    local ret_code=0

    printf "\n### Begin Nvidia Setup ###\n"

    # Ensure an Nvidia card is present
    if nvidiaGraphics; then
        # Gnome background logo extension can sometimes cause problems
        local package="gnome-shell-extension-background-logo"
        runCommand "yum -y remove $package" "Removing '$package'..."
        ret_code=$(($ret_code|$?))

        # Ensure there are no existing Nvidia packages
        runCommand "yum -y remove '*nvidia*'" "Removing all existing Nvidia packages..."
        ret_code=$(($ret_code|$?))

        # Install required packages
        installPackage "kernel-devel"
        ret_code=$(($ret_code|$?))
        installPackage "acpi"
        ret_code=$(($ret_code|$?))

        # Install Nvidia packages
        installPackage "nvidia-driver"
        ret_code=$(($ret_code|$?))
        installPackage "akmod-nvidia"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-driver-libs"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-driver-libs.i686"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-driver-cuda"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-driver-cuda-libs"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-driver-cuda-libs.i686"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-modprobe"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-settings"
        ret_code=$(($ret_code|$?))
        installPackage "nvidia-xconfig"
        ret_code=$(($ret_code|$?))
        installPackage "cuda"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-libs"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-libs.i686"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-extra-libs"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-extra-libs.i686"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-cli-tools"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-devel.i686"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-docs"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-nsight"
        ret_code=$(($ret_code|$?))
        installPackage "cuda-nvvp"
        ret_code=$(($ret_code|$?))

        # Backup initramfs and create a new one
        runCommand "mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img" "Backing up initramfs image..."
        ret_code=$(($ret_code|$?))
        runCommand "dracut /boot/initramfs-$(uname -r).img $(uname -r)" "Creating new initramfs image..."
        ret_code=$(($ret_code|$?))

        # Install packages for video acceleration
        installPackage "vdpauinfo"
        ret_code=$(($ret_code|$?))
        installPackage "libva-vdpau-driver"
        ret_code=$(($ret_code|$?))
        installPackage "libva-utils"
        ret_code=$(($ret_code|$?))

        # Fix Plymouth
        installPackage "plymouth-theme-charge"
        ret_code=$(($ret_code|$?))
        runCommand "plymouth-set-default-theme charge" "Setting the Plymouth theme..."
        ret_code=$(($ret_code|$?))
        runCommand "/usr/libexec/plymouth/plymouth-update-initrd" "Saving Plymouth settings..."
        ret_code=$(($ret_code|$?))

        # NOTE: Grub must be reconfigured for Nvidia drivers.
        #       This is done in the 'system-tweaks' script.
    else
        echo "No Nvidia device detected!"
    fi

    printf "### End Nvidia Setup ###\n"

    return $ret_code
}

nvidiaSetupMain
return $?
