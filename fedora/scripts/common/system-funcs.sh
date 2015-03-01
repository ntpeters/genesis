# Provides functions for configuring working with the system

# Check if we were sourced or executed
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    echo "This script must be sourced, not executed!"
    exit 1
fi

# Source general funcs it it hasn't been sourced
if [ -z "${genesis_general_funcs}" ]; then
    source ""$genesis_common"/general-funcs.sh"
fi

# Checks if a service exists or not
# Input:
#   $1 - The name of the service to check for
# Output:
#   0 if the service exists
function serviceExists() {
    local service="$@"
    local cmd="systemctl list-unit-files --all | grep --fixed-strings --quiet "$service""
    eval "$cmd"
    return $?
}

# Enables an existing system service
# Input:
#   $1 - Name of the service to enable
function enableService() {
    local ret_code=0

    local service="$@"

    if serviceExists "$service"; then
        if systemctl is-enabled "$service" > /dev/null 2>&1; then
            echo "Service '"$service"' is already enabled!"
        else
            (systemctl enable "$service") &
            progress "$!" "Enabling '"$service"' service..."
            ret_code=$(($ret_code|$?))
        fi
    else
        echo "Service '"$service"' does not exist!"
    fi

    return $ret_code
}

# Disables an existing system service
# Input:
#   $1 - Name of the service to disable
function disableService() {
    local ret_code=0

    local service="$@"

    if serviceExists "$service"; then
        if systemctl is-enabled "$service" > /dev/null 2>&1; then
            (systemctl disable "$service") &
            progress "$!" "Disabling '"$service"' service..."
            ret_code=$(($ret_code|$?))
        else
            echo "Service '"$service"' is already disabled!"
        fi
    else
        echo "Service '"$service"' does not exist!"
    fi

    return $ret_code
}

# Rewrites fstab with optimizations
function update_fstab() {
    local ret_code=0

    echo "Updating fstab..."

    # Original fstab location
    local fstab="/etc/fstab"
    # Temp fstab location
    local fstab_tmp="/tmp/fstab"
    # Updates the fstab file
    local save_fstab=" > "$fstab_tmp".tmp && mv "$fstab_tmp".tmp "$fstab_tmp""

    # Create a temp copy of fstab to modify
    cp --force "$fstab" "$fstab_tmp"
    ret_code=$(($ret_code|$?))

    # Common options
    local std_options="noatime,nodiratime"
    # Enable writeback if system is backed by a battery
    if hasBattery; then
        std_options=""$std_options",data=writeback"
    fi
    # SSD specific options
    local ssd_options=""
    # Non-SSD specific options
    local hdd_options=""
    # Update options if a system is backed by a battery
    if hasBattery; then
        ssd_options=""$std_options",commit=60,nobh,barrier=0"
        hdd_options=""$std_options",commit=15"
    else
        ssd_options=""$std_options",commit=20"
        hdd_options=""$std_options""
    fi

    # Iterate over all system disks
    for disk in `\ls --directory /sys/block/sd*`; do
        local rot=""$disk"/queue/rotational"
        local sched=""$disk"/queue/scheduler"

        # Check if the current disk is an SSD
        local is_ssd=1
        if [[ `cat "$rot"` -eq 0 ]]; then
            if [[ -w "$sched" ]]; then
                is_ssd=0
            fi
        fi

        # Set the correct disk options for type of disk
        local disk_options="$hdd_options"
        if [ $is_ssd = 0 ]; then
            disk_options="$ssd_options"
        fi

        # Convert all tabs in 'fstab' to spaces
        local untabify="expand "$fstab_tmp""
        eval "$untabify" "$save_fstab"
        ret_code=$(($ret_code|$?))

        # Get the device name (ie. sda or sdb)
        local device=`\echo "${disk##*/}"`
        # Iterate over list of partitions
        local df_list=`\df`
        while read -r line; do
            # Check if the current partition blongs to the current device
            if [[ "$line" = *"$device"* ]]; then
                # Get the mount point for this partition
                local mount_point=`\echo "$line" | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=6`
                local partition=`\echo "$line" | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=1`

                local apply_options=""
                while read fstab_line; do
                    local line_mount=`echo "$fstab_line" | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=2`
                    if [[ "$line_mount" = "$mount_point" ]]; then
                        local existing_options=`echo "$fstab_line" | tr --squeeze-repeats ' ' | cut --delimiter=' ' --fields=4`
                        for option in $(echo "$disk_options" | tr "," " "); do
                            if [[ "$option" != "" && "$existing_options" != *"$option"* ]]; then
                                apply_options=""$apply_options","$option""
                            fi
                        done
                    fi
                done < "$fstab"

                # Construct the command to update fstab
                local update_cmd="awk '\$2~\"^"$mount_point"\$\"{\$4=\$4\""$apply_options"\"}1' OFS=\"\t\" "$fstab_tmp""

                # Enable writeback on this device if it is set in its options
                if [[ "$apply_options" = *"data=writeback"* ]]; then
                    local enable_writeback="tune2fs -o journal_data_writeback "$partition""
                    runCommand "$enable_writeback" "Enabling writeback journaling on '"$partition"'..."
                    ret_code=$(($ret_code|$?))
                fi

                # Update fstab if options exist to be added to this entry
                if [[ "$apply_options" != "" ]]; then
                    eval "$update_cmd" "$save_fstab"
                    ret_code=$(($ret_code|$?))
                fi
            fi
        done <<< "${df_list}"
    done

    local add_discard_to_swap=0
    local add_tmpfs_tmp=0
    local add_tmpfs_chrome_cache=0
    while read fstab_line; do
        if [[ "$fstab_line" = *"/tmp"* ]]; then
            add_tmpfs_tmp=1
        fi
        if [[ "$fstab_line" = *""$user_home"/.cache/google-chrome"* ]]; then
            add_tmpfs_chrome_cache=1
        fi
        if [[ "$fstab_line" = *"swap"* && "$fstab_line" = *"discard"* ]]; then
            add_discard_to_swap=1
        fi
    done < "$fstab"

    # Update swap in fstab if this is an SSD
    if hasSSD; then
        if [ $add_discard_to_swap = 0 ]; then
            local swap="awk '\$2~\"^swap\$\"{\$4=\$4\",discard\"}1' OFS=\"\t\" "$fstab_tmp""
            eval "$swap" "$save_fstab"
            ret_code=$(($ret_code|$?))
        fi
    fi

    # Add tmpfs drives for temp files and caches
    if [ $add_tmpfs_tmp = 0 ]; then
        printf "tmpfs\t/tmp\ttmpfs\tnoatime,nodiratime,nosuid,nodev,noexec,mode=1777,size=1536M\t0\t0\n" >> "$fstab_tmp"
        ret_code=$(($ret_code|$?))
    fi
    if [ $add_tmpfs_chrome_cache = 0 ]; then
        if [ ! -z "${user_home+x}" ]; then
            printf "tmpfs\t"$user_home"/.cache/google-chrome\ttmpfs\tnoatime,nodiratime,nosuid,nodev,size=512M\t0\t0\n" >> "$fstab_tmp"
            ret_code=$(($ret_code|$?))
        fi
    fi

    # Backup original fstab
    backupFile "$fstab"

    # Copy the new fstab into place
    cp --force "$fstab_tmp" "$fstab"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Updates grub config based on detected framebuffer support and graphics card
function update_grub() {
    local ret_code=0

    echo "Updating grub config..."

    # hwinfo command is required to detect supported Vesa framebuffers
    local hwinfo_installed=0
    if ! isInstalled "hwinfo"; then
        installFromRepo "hwinfo"
        if [ ! $? ]; then
            hwinfo_installed=1
        fi
    fi

    # Create a copy of the default grub file
    local grub_file="/tmp/grub.default"
    local create_tmp_file="cp --force "$genesis_fedora_assets"/grub.default "$grub_file""
    eval ${create_tmp_file}
    ret_code=$(($ret_code|$?))

    # Used to save the file after each edit
    local save_file=" > "$grub_file".tmp && mv --force "$grub_file".tmp "$grub_file""

    # Ensure Vesa framebuffer info is loaded
    if [[ -z "${vesa_max_res+x}" || -z "${vesa_max_mode+x}" ]]; then
        loadVesaInfo
        ret_code=$(($ret_code|$?))
        echo "Loaded Vesa framebuffer info"
    fi

    # Contains all additional kernel params
    local params=""

    # Add extra params if using nvidia graphics
    if commandExists "nvidia-smi"; then
        printf "Set kernel params for "
        params="nomodeset rd.driver.blacklist=nouveau"

        # Add deprecated 'vga' param if using a legacy driver
        if [[ "$nvidia_driver_version" != "" && "$nvidia_driver_version" = *"Legacy"* ]]; then
            if [ ! -z "${vesa_max_mode+x}" ]; then
                params=""$params" vga="$vesa_max_mode""
                printf "legacy "
            fi
        fi
        printf "Nvidia support\n"
    fi

    # If there is an SSD, set the default scheduler to deadline
    if hasSSD; then
        params=""$params" elevator=deadline"
        ret_code=$(($ret_code|$?))
        echo "Grub I/O scheduler set to deadline"
    fi

    # Check if writeback journaling is enabled on any device
    local writeback_enabled=1
    for partition in `lsblk --output="name" --noheadings --nodeps --inverse --paths`; do
        local check="tune2fs -l "$partition" | grep --ignore-case 'journal_data_writeback'"
        eval "$check" > /dev/null 2>&1
        writeback_enabled=0
    done

    # If writeback journaling is enabled on any device, add param to grub
    if [ $writeback_enabled = 0 ]; then
        params=""$params" rootflags=data=writeback"
        echo "Enabled writeback journaling"
    fi

    # If a swap device exists, enable zswap
    if hasSwap; then
        params=""$params" zswap.enabled=1 zswap.zpool=zsmalloc"
        echo "Enabled ZSwap"
    fi

    # Setup command to update grub kernel params
    local update_kernel_params=""
    if [ ! -z "${params+x}" ]; then
        update_kernel_params="awk -F'=\"' '\$1~\"^GRUB_CMDLINE_LINUX\$\"{\$2=\"\b=\\\"\"\$2\"\b\b"$params"\\\"\"}1' "$grub_file""
    fi

    # Setup command to update grub resolution
    local update_graphics=""
    if [ ! -z "${vesa_max_res+x}" ]; then
        update_graphics="awk -F'=\"' '\$1~\"^GRUB_GFXMODE\$\"{\$2=\"\b=\\\""$vesa_max_res"\\\"\"}1' "$grub_file""
    fi

    # Update grub kernel params
    if [ ! -z "${update_kernel_params+x}" ]; then
        eval ${update_kernel_params}${save_file}
        ret_code=$(($ret_code|$?))
        echo "Updated grub kernel params"
    fi

    # Update the grub resolution
    if [ ! -z "${update_graphics+x}" ]; then
        eval ${update_graphics}${save_file}
        ret_code=$(($ret_code|$?))
        echo "Updated grub resolution"
    fi

    # Fix formatting issues in file and copy it back into place
    local apply="cat "$grub_file" | col --no-backspaces >> "$grub_file".tmp"
    if [[ ! -z "${update_kernel_params+x}" || ! -z "${update_graphics+x}" ]]; then
        rm -f ""$grub_file".tmp"
        ret_code=$(($ret_code|$?))
        eval "$apply"
        ret_code=$(($ret_code|$?))
        mv ""$grub_file".tmp" "$grub_file"
        ret_code=$(($ret_code|$?))
        echo "Fixed formatting in grub config"
    fi

    # Backup grub defaults file
    backupFile "/etc/default/grub"

    # Copy new grub defaults file
    runCommand "cp --force "$grub_file" /etc/default/grub" "Copying custom default grub config..."
    ret_code=$(($ret_code|$?))

    # Ensure grub font file exists
    if [[ -f "/boot/grub2/fonts/unicode.pf2" ]]; then
        runCommand "grub2-mkfont --output=/boot/grub2/fonts/LiberationMono-Regular.pf2 --size=24 /usr/share/fonts/liberation/LiberationMono-Regular.ttf" "Creating grub font file..."
        ret_code=$(($ret_code|$?))
    fi

    # Generate updated grub config
    runCommand "grub2-mkconfig --output=/boot/grub2/grub.cfg" "Generating grub config..."
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Installs a udev rule to set I/O schedulers
# SSD: noop
# HDD: cfq
function setIOSchedulers() {
    echo "Setting I/O Schedulers..."

    local scheduler_rule="/etc/udev/rules.d/60-io_schedulers.rules"
    cat <<EOF | tee "$scheduler_rule" > /dev/null 2>&1
# Set noop scheduler for non-rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="noop"
# Set cfq scheduler for rotating disks
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="cfq"
EOF

    return $?
}

# Writes tweaks to sysctl.conf
function update_sysctl() {
    local ret_code=0

    echo "Updating sysctl..."

    # Path to new sysctl file for memory tweaks
    local sysctl_vm="/etc/sysctl.d/60-mem-tweaks.conf"

    # If the file exists, remove it
    if [ -f "$sysctl_vm" ]; then
        rm --force "$sysctl_vm" > /dev/null 2>&1
    fi
    # Create the tweaks file
    touch "$sysctl_vm" > /dev/null 2>&1

    # Strongly discourage swapping
    local swappiness="vm.swappiness=1"
    # Prefer retaining caches
    local cache_pressure="vm.vfs_cache_pressure=50"
    # Percent of memory when dirty pages are written in the background
    local background_ratio="vm.dirty_background_ratio=5"
    # Percent of memory when dirty pages are force flushed
    local dirty_ratio="vm.dirty_ratio=30"

    # Write tweaks to file
    echo "$swappiness" >> "$sysctl_vm"
    ret_code=$(($ret_code|$?))
    echo "$cache_pressure" >> "$sysctl_vm"
    ret_code=$(($ret_code|$?))
    echo "$background_ratio" >> "$sysctl_vm"
    ret_code=$(($ret_code|$?))
    echo "$dirty_ratio" >> "$sysctl_vm"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Enables Kernel Samepage Merging
function enableKSM() {
    local ret_code=0

    echo "Enabling Kernel Samepage Merging..."

    installFromRepo "ksm"
    enableService "ksm"
    enableService "ksmtuned"

    local ksmtuned="/etc/ksmtuned.conf"
    # Enables KSM
    local ksm_run="run=1"
    # Reduce frequency of memory scans searching for duplicate pages
    local ksm_sleep="sleep_millisecs=200"

    # Backup the original conf file
    backupFile "$ksmtuned"

    # Remove the original conf file
    if [ -f "$ksmtuned" ]; then
        rm --force "$ksmtuned" > /dev/null 2>&1
    fi
    # Create the new conf file
    touch "$ksmtuned" > /dev/null 2>&1

    echo "$ksm_run" >> "$ksmtuned"
    ret_code=$(($ret_code|$?))
    echo "$ksm_sleep" >> "$ksmtuned"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Enables Profile Sync Daemon
function enablePSD() {
    local ret_code=0

    echo "Enabling Profile Sync Daemon..."

    installFromRepo "profile-sync-daemon"
    ret_code=$(($ret_code|$?))
    enableService "psd"
    ret_code=$(($ret_code|$?))

    local psdconf="/etc/psd.conf"
    # Set the users PSD should be active for
    local users="USERS=\""$username"\""
    # Reduces memory overhead
    local overlay="USER_OVERLAYFS=\"yes\""

    # Backup the original conf file
    backupFile "$psdconf"

    # Remove the original conf file
    if [ -f "$psdconf" ]; then
        rm --force "$psdconf" > /dev/null 2>&1
    fi
    # Create the new conf file
    touch "$psdconf" > /dev/null 2>&1

    echo "$users" >> "$psdconf"
    ret_code=$(($ret_code|$?))
    echo "$overlay" >> "$psdconf"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Update SELinux configuration
function configureSELinux() {
    # Set SELinux to load in permissive mode
    sed -i 's/SELINUX=.*$/SELINUX=permissive/g' /etc/selinux/config

    # Put SELinux into permissive mode now
    setenforce 0
}

# Denotes that this file has been sourced
genesis_fedora_system_funcs=0
