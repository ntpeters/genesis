# Provides functions to perform custom installs of third party programs/items

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

# Installs InteilliJ Ultimate
function install-intellij-ultimate() {
    local name="IntelliJ Ultimate"
    local dl_link=`curl -s --data "os=linux&edition=IU" https://www.jetbrains.com/idea/download/download_thanks.jsp | grep -m 1 -o http://download\.jetbrains\.com/idea/ideaIU-.*\.tar\.gz`
    local install_path="/opt/idea"

    installRemoteTarball "$name" "$dl_link" "$install_path" "--strip-components=1"
    return $?
}

# Installs Android Studio
function install-android-studio() {
    local name="Android Studio"
    local dl_link=`curl -s -N http://developer.android.com/sdk/index.html | grep -m 1 -o https://dl\.google\.com/dl/android/studio/ide-zips/.*/android-studio-ide-.*linux\.zip`
    local install_path="/opt/android-studio"

    installRemoteZip "$name" "$dl_link" "$install_path"
    return $?
}

# Installs Scala
# Rather than install the version available in the repository, this will get the
# most recent version from the Scala site.
function install-scala() {
    local name="Scala"
    local dl_link=`curl -s -N http://www.scala-lang.org/download/ | grep -m 1 -o http://downloads\.typesafe\.com/scala/.*/scala-.*\.tgz`
    local install_path="/opt/scala"

    installRemoteTarball "$name" "$dl_link" "$install_path" "--strip-components=1"
    return $?
}

# Installs Sublime Text 3
function install-sublime() {
    local name="Sublime Text 3"
    local dl_link=`curl -s -N http://www.sublimetext.com/3 | grep -m 1 -o http://c758482\.r82\.cf2\.rackcdn\.com/sublime_text_3_build_.*_x64\.tar\.bz2`
    local install_path="/opt/sublime"

    installRemoteTarball "$name" "$dl_link" "$install_path" "--strip-components=1"
    return $?
}

# Installs and configures Oracle JDK
function install-oracle-java() {
    local ret_code=0

    local name="Oracle JDK"
    local jdk_site=`curl -s -N http://www.oracle.com/technetwork/java/javase/downloads/index.html | tr ' ' '\n' | grep -m 1 -o /technetwork/java/javase/downloads/jdk.-downloads.*\.html`
    local jdk_page="http://www.oracle.com"$jdk_site""
    local dl_link=`curl -s -N "$jdk_page" | grep -m 1 -o http://download\.oracle\.com/otn-pub/java/jdk.*/jdk-.*-linux-x64\.rpm`
    local dl_path="/tmp/jdk-linux-x64.rpm"
    local curl_flags="--header \"Cookie: oraclelicense=a\""

    download "$dl_link" "$dl_path" "$name" "$curl_flags"
    ret_code=$(($ret_code|$?))
    installFromLocal "$dl_path" "$name"
    ret_code=$(($ret_code|$?))

    local java_setup="mkdir -p /usr/lib/jvm /usr/lib/jvm-exports && \
    alternatives --install /usr/bin/java java /usr/java/latest/bin/java 200000 \
    --slave /usr/lib/jvm/jre jre /usr/java/latest/jre \
    --slave /usr/lib/jvm-exports/jre jre_exports /usr/java/latest/jre/lib \
    --slave /usr/bin/keytool keytool /usr/java/latest/jre/bin/keytool \
    --slave /usr/bin/orbd orbd /usr/java/latest/jre/bin/orbd \
    --slave /usr/bin/pack200 pack200 /usr/java/latest/jre/bin/pack200 \
    --slave /usr/bin/rmid rmid /usr/java/latest/jre/bin/rmid \
    --slave /usr/bin/rmiregistry rmiregistry /usr/java/latest/jre/bin/rmiregistry \
    --slave /usr/bin/servertool servertool /usr/java/latest/jre/bin/servertool \
    --slave /usr/bin/tnameserv tnameserv /usr/java/latest/jre/bin/tnameserv \
    --slave /usr/bin/unpack200 unpack200 /usr/java/latest/jre/bin/unpack200 \
    --slave /usr/share/man/man1/java.1 java.1 /usr/java/latest/man/man1/java.1 \
    --slave /usr/share/man/man1/keytool.1 keytool.1 /usr/java/latest/man/man1/keytool.1 \
    --slave /usr/share/man/man1/orbd.1 orbd.1 /usr/java/latest/man/man1/orbd.1 \
    --slave /usr/share/man/man1/pack200.1 pack200.1 /usr/java/latest/man/man1/pack200.1 \
    --slave /usr/share/man/man1/rmid.1.gz rmid.1 /usr/java/latest/man/man1/rmid.1 \
    --slave /usr/share/man/man1/rmiregistry.1 rmiregistry.1 /usr/java/latest/man/man1/rmiregistry.1 \
    --slave /usr/share/man/man1/servertool.1 servertool.1 /usr/java/latest/man/man1/servertool.1 \
    --slave /usr/share/man/man1/tnameserv.1 tnameserv.1 /usr/java/latest/man/man1/tnameserv.1 \
    --slave /usr/share/man/man1/unpack200.1 unpack200.1 /usr/java/latest/man/man1/unpack200.1 && \
    alternatives --auto java && \
    alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000 \
    --slave /usr/lib/jvm/java java_sdk /usr/java/latest \
    --slave /usr/lib/jvm-exports/java java_sdk_exports /usr/java/latest/lib \
    --slave /usr/bin/appletviewer appletviewer /usr/java/latest/bin/appletviewer \
    --slave /usr/bin/apt apt /usr/java/latest/bin/apt \
    --slave /usr/bin/extcheck extcheck /usr/java/latest/bin/extcheck \
    --slave /usr/bin/jar jar /usr/java/latest/bin/jar \
    --slave /usr/bin/jarsigner jarsigner /usr/java/latest/bin/jarsigner \
    --slave /usr/bin/javadoc javadoc /usr/java/latest/bin/javadoc \
    --slave /usr/bin/javah javah /usr/java/latest/bin/javah \
    --slave /usr/bin/javap javap /usr/java/latest/bin/javap \
    --slave /usr/bin/jconsole jconsole /usr/java/latest/bin/jconsole \
    --slave /usr/bin/jdb jdb /usr/java/latest/bin/jdb \
    --slave /usr/bin/jhat jhat /usr/java/latest/bin/jhat \
    --slave /usr/bin/jinfo jinfo /usr/java/latest/bin/jinfo \
    --slave /usr/bin/jmap jmap /usr/java/latest/bin/jmap \
    --slave /usr/bin/jps jps /usr/java/latest/bin/jps \
    --slave /usr/bin/jrunscript jrunscript /usr/java/latest/bin/jrunscript \
    --slave /usr/bin/jsadebugd jsadebugd /usr/java/latest/bin/jsadebugd \
    --slave /usr/bin/jstack jstack /usr/java/latest/bin/jstack \
    --slave /usr/bin/jstat jstat /usr/java/latest/bin/jstat \
    --slave /usr/bin/jstatd jstatd /usr/java/latest/bin/jstatd \
    --slave /usr/bin/native2ascii native2ascii /usr/java/latest/bin/native2ascii \
    --slave /usr/bin/policytool policytool /usr/java/latest/bin/policytool \
    --slave /usr/bin/rmic rmic /usr/java/latest/bin/rmic \
    --slave /usr/bin/schemagen schemagen /usr/java/latest/bin/schemagen \
    --slave /usr/bin/serialver serialver /usr/java/latest/bin/serialver \
    --slave /usr/bin/wsgen wsgen /usr/java/latest/bin/wsgen \
    --slave /usr/bin/wsimport wsimport /usr/java/latest/bin/wsimport \
    --slave /usr/bin/xjc xjc /usr/java/latest/bin/xjc \
    --slave /usr/share/man/man1/appletviewer.1 appletviewer.1 /usr/java/latest/man/man1/appletviewer.1 \
    --slave /usr/share/man/man1/apt.1 apt.1 /usr/java/latest/man/man1/apt.1 \
    --slave /usr/share/man/man1/extcheck.1 extcheck.1 /usr/java/latest/man/man1/extcheck.1 \
    --slave /usr/share/man/man1/jar.1 jar.1 /usr/java/latest/man/man1/jar.1 \
    --slave /usr/share/man/man1/jarsigner.1 jarsigner.1 /usr/java/latest/man/man1/jarsigner.1 \
    --slave /usr/share/man/man1/javac.1 javac.1 /usr/java/latest/man/man1/javac.1 \
    --slave /usr/share/man/man1/javadoc.1 javadoc.1 /usr/java/latest/man/man1/javadoc.1 \
    --slave /usr/share/man/man1/javah.1 javah.1 /usr/java/latest/man/man1/javah.1 \
    --slave /usr/share/man/man1/javap.1 javap.1 /usr/java/latest/man/man1/javap.1 \
    --slave /usr/share/man/man1/jconsole.1 jconsole.1 /usr/java/latest/man/man1/jconsole.1 \
    --slave /usr/share/man/man1/jdb.1 jdb.1 /usr/java/latest/man/man1/jdb.1 \
    --slave /usr/share/man/man1/jhat.1 jhat.1 /usr/java/latest/man/man1/jhat.1 \
    --slave /usr/share/man/man1/jinfo.1 jinfo.1 /usr/java/latest/man/man1/jinfo.1 \
    --slave /usr/share/man/man1/jmap.1 jmap.1 /usr/java/latest/man/man1/jmap.1 \
    --slave /usr/share/man/man1/jps.1 jps.1 /usr/java/latest/man/man1/jps.1 \
    --slave /usr/share/man/man1/jrunscript.1 jrunscript.1 /usr/java/latest/man/man1/jrunscript.1 \
    --slave /usr/share/man/man1/jsadebugd.1 jsadebugd.1 /usr/java/latest/man/man1/jsadebugd.1 \
    --slave /usr/share/man/man1/jstack.1 jstack.1 /usr/java/latest/man/man1/jstack.1 \
    --slave /usr/share/man/man1/jstat.1 jstat.1 /usr/java/latest/man/man1/jstat.1 \
    --slave /usr/share/man/man1/jstatd.1 jstatd.1 /usr/java/latest/man/man1/jstatd.1 \
    --slave /usr/share/man/man1/native2ascii.1 native2ascii.1 /usr/java/latest/man/man1/native2ascii.1 \
    --slave /usr/share/man/man1/policytool.1 policytool.1 /usr/java/latest/man/man1/policytool.1 \
    --slave /usr/share/man/man1/rmic.1 rmic.1 /usr/java/latest/man/man1/rmic.1 \
    --slave /usr/share/man/man1/schemagen.1 schemagen.1 /usr/java/latest/man/man1/schemagen.1 \
    --slave /usr/share/man/man1/serialver.1 serialver.1 /usr/java/latest/man/man1/serialver.1 \
    --slave /usr/share/man/man1/wsgen.1 wsgen.1 /usr/java/latest/man/man1/wsgen.1 \
    --slave /usr/share/man/man1/wsimport.1 wsimport.1 /usr/java/latest/man/man1/wsimport.1 \
    --slave /usr/share/man/man1/xjc.1 xjc.1 /usr/java/latest/man/man1/xjc.1 && \
    alternatives --auto javac"

    runCommand "$java_setup" "Performing Oracle JDK Setup..."
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Installs the Inconsolata-G for Powerline font
function install-inconsolata-powerline() {
    local ret_code=0

    local name="Inconsolata-g for Powerline"
    local dl_link="https://github.com/powerline/fonts/raw/master/Inconsolata-g/Inconsolata-g%20for%20Powerline.otf"
    local dl_path="/usr/share/fonts/Inconsolata-g-Powerline.otf"

    download "$dl_link" "$dl_path" "$name" ""
    ret_code=$(($ret_code|$?))
    runCommand "fc-cache -f" "Rebuilding font cache..."
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Installs the Paper GTK theme
function install-paper-gtk-theme() {
    local ret_code=0

    local name="Paper GTK Theme"
    local dl_link="https://github.com/snwh/paper-gtk-theme/raw/master/paper-gtk-theme.tar.gz"
    local dl_path="/tmp/paper.tar.gz"
    local tmp_path="/tmp/paper"
    local unpack_cmd="tar -zxf "$dl_path" -C"$tmp_path""

    download "$dl_link" "$dl_path" "$name" ""
    ret_code=$(($ret_code|$?))
    mkdir -p "$tmp_path"
    ret_code=$(($ret_code|$?))
    runCommand "$unpack_cmd" "Extracting ""$name""..."
    ret_code=$(($ret_code|$?))

    local install_cmd="cp -R \""$tmp_path"/Paper\" \"/usr/share/themes/\""
    runCommand "$install_cmd" "Installing ""$name""..."
    ret_code=$(($ret_code|$?))
    chmod -R 755 "/usr/share/themes/Paper"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Installs the Paper icon theme
function install-paper-icon-theme() {
    local ret_code=0

    local name="Paper Icon Theme"
    local dl_link="https://github.com/snwh/paper-icon-theme/raw/master/paper-icon-theme.tar.gz"
    local dl_path="/tmp/paper-icons.tar.gz"
    local tmp_path="/tmp/paper-icons"
    local unpack_cmd="tar -zxf "$dl_path" -C"$tmp_path""

    download "$dl_link" "$dl_path" "$name" ""
    ret_code=$(($ret_code|$?))
    mkdir -p "$tmp_path"
    ret_code=$(($ret_code|$?))
    runCommand "$unpack_cmd" "Extracting ""$name""..."
    ret_code=$(($ret_code|$?))

    local install_cmd="cp -R \""$tmp_path"/Paper\" \"/usr/share/icons/Paper\""
    runCommand "$install_cmd" "Installing ""$name""..."
    ret_code=$(($ret_code|$?))
    chmod -R 755 "/usr/share/icons/Paper"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Installs the Bridge cursor theme
function install-bridge-cursor-theme() {
    local name="Bridge Cursor Theme"
    local dl_link="http://gnome-look.org/CONTENT/content-files/164587-bridge.tar.gz"
    local install_path="/usr/share/icons/bridge"

    installRemoteTarball "$name" "$dl_link" "$install_path" "--strip-components=1"
    return $?
}

# Installs Antigen for managing ZSH plugins
function install-antigen() {
    local ret_code=0

    local antigen_path=""$user_home"/.antigen/antigen.zsh"
    local cmd="curl https://raw.githubusercontent.com/zsh-users/antigen/master/antigen.zsh -o $antigen_path --create-dirs"

    if ! programExists curl; then
        installPackage curl
        ret_code=$(($ret_code|$?))
    fi

    runCommand "$cmd" "Installing Antigen..."
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Installs Vundle for managing Vim plugins
function install-vundle() {
    local ret_code=0

    local vundle_path=""$user_home"/.vim/bundle/Vundle.vim"
    local cmd="git clone https://github.com/gmarik/Vundle.vim.git $vundle_path"

    if ! programExists git; then
        installPackage git
        ret_code=$(($ret_code|$?))
    fi

    runCommand "$cmd" "Installing Vundle..."
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install RPM Fusion repos
function install-repo-rpmfusion() {
    local ret_code=0

    installRepo "rpmfusion-free" "yum -y localinstall --nogpgcheck http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    ret_code=$(($ret_code|$?))
    enableRepo "rpmfusion-free"
    ret_code=$(($ret_code|$?))
    installRepo "rpmfusion-nonfree" "yum -y localinstall --nogpgcheck http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    ret_code=$(($ret_code|$?))
    enableRepo "rpmfusion-nonfree"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install Adobe Flash plugin repository
function install-repo-flash-plugin() {
    local ret_code=0

    installRepo "fedora-flash-plugin" "yum-config-manager --add-repo=http://negativo17.org/repos/fedora-flash-plugin.repo"
    ret_code=$(($ret_code|$?))
    enableRepo "fedora-flash-plugin"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install Skype repository
function install-repo-skype() {
    local ret_code=0

    installRepo "fedora-skype" "yum-config-manager --add-repo=http://negativo17.org/repos/fedora-skype.repo"
    ret_code=$(($ret_code|$?))
    enableRepo "fedora-skype"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install Handbrake repository
function install-repo-handbrake() {
    local ret_code=0

    installRepo "fedora-handbrake" "yum-config-manager --add-repo=http://negativo17.org/repos/fedora-handbrake.repo"
    ret_code=$(($ret_code|$?))
    enableRepo "fedora-handbrake"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install CDR-tools repository
function install-repo-cdrtools() {
    local ret_code=0

    installRepo "fedora-cdrtools" "yum-config-manager --add-repo=http://negativo17.org/repos/fedora-cdrtools.repo"
    ret_code=$(($ret_code|$?))
    enableRepo "fedora-cdrtools"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install repository for Numix themes
function install-repo-numix-themes() {
    local ret_code=0

    installRepo "home_paolorotolo_numix" "yum-config-manager --add-repo=http://download.opensuse.org/repositories/home:/paolorotolo:/numix/Fedora_21/home:paolorotolo:numix.repo"
    ret_code=$(($ret_code|$?))
    enableRepo "home_paolorotolo_numix"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install hwinfo repository
function install-repo-hwinfo() {
    local ret_code=0

    installRepo "baoboa-hwinfo" "yum-config-manager --add-repo=https://copr.fedoraproject.org/coprs/baoboa/hwinfo/repo/fedora-21/baoboa-hwinfo-fedora-21.repo"
    ret_code=$(($ret_code|$?))
    enableRepo "baoboa-hwinfo"
    ret_code=$(($ret_code|$?))

    return $ret_code
}

# Install repository for Nvidia drivers
function install-repo-nvidia() {
    local ret_code=0

    if ! repoInstalled "fedora-nvidia"; then
        if nvidiaGraphics; then
            echo "Checking Nvidia device to configure correct driver repository..."

            nvidia_repo_link=""
            if [[ "$nvidia_driver_version" == *"340"* ]]; then
                nvidia_repo_link="http://negativo17.org/repos/fedora-nvidia-340.repo"
            elif [[ "$nvidia_driver_version" != "" && "$nvidia_driver_version" != *"Legacy"* ]]; then
                nvidia_repo_link="http://negativo17.org/repos/fedora-nvidia.repo"
            fi

            if [ "$nvidia_repo_link" != "" ]; then
                installRepo "fedora-nvidia" "yum-config-manager --add-repo="$nvidia_repo_link""
                ret_code=$(($ret_code|$?))
                enableRepo "fedora-nvidia"
                ret_code=$(($ret_code|$?))
            else
                echo "The Negativo17 Nvidia repository does not support legacy drivers older than the 340 series!"
            fi
        else
            echo "Not configuring Nvidia repository. No Nvidia device found!"
        fi
    else
        echo "Repository 'fedora-nvidia' is already installed!"
    fi

    return $ret_code
}


# Denotes that this file has been sourced
genesis_fedora_custom_install_funcs=0
