#!/bin/bash

# Global Variables
INSTALL_LOG="/var/log/post_install.log"
REBOOT_REQUIRED=false

# Color codes
GREEN="\033[0;32m"
BOLD_GREEN="\033[1;32m"
NO_COLOR="\033[0m"

# Log Function
log_info() {
    printf "%b[%s] INFO: %s%b\n" "${BOLD_GREEN}" "$(date +'%Y-%m-%d %H:%M:%S')" "$1" "${NO_COLOR}" | tee -a "$INSTALL_LOG"
}

log_error() {
    printf "%b[%s] ERROR: %s%b\n" "${RED}" "$(date +'%Y-%m-%d %H:%M:%S')" "$1" "${NO_COLOR}" >&2 | tee -a "$INSTALL_LOG"
}

# Confirmation Function
confirm_installation() {
    local prompt="$1"
    local response
    read -r -p "$prompt (y/n): " response
    [[ "$response" =~ ^[yY]$ ]]
}

# Function to update system
update_system() {
    confirm_installation "Do you want to update the system?" || return 0
    log_info "Updating the system..."
    if ! sudo dnf update -y && sudo dnf upgrade -y; then
        log_error "Failed to update the system."
        return 1
    fi
    REBOOT_REQUIRED=true
}

# Function to install EPEL repository
install_epel() {
    confirm_installation "Do you want to install the EPEL repository?" || return 0
    log_info "Installing EPEL repository..."
    if ! sudo dnf install epel-release -y; then
        log_error "Failed to install EPEL repository."
        return 1
    fi
}

# Function to install essential tools
install_essential_tools() {
    confirm_installation "Do you want to install essential tools?" || return 0
    log_info "Installing essential tools..."
    if ! sudo dnf install -y vim git wget curl net-tools htop; then
        log_error "Failed to install essential tools."
        return 1
    fi
}

# Function to configure firewall
configure_firewall() {
    confirm_installation "Do you want to configure the firewall?" || return 0
    log_info "Configuring the firewall..."
    if ! sudo systemctl start firewalld || ! sudo systemctl enable firewalld; then
        log_error "Failed to start and enable firewalld."
        return 1
    fi
    if ! sudo firewall-cmd --permanent --add-service=ssh || \
       ! sudo firewall-cmd --permanent --add-service=http || \
       ! sudo firewall-cmd --permanent --add-service=https || \
       ! sudo firewall-cmd --reload; then
        log_error "Failed to configure firewall rules."
        return 1
    fi
}

# Function to set up SELinux
setup_selinux() {
    confirm_installation "Do you want to set up SELinux?" || return 0
    log_info "Setting up SELinux..."
    if ! sudo setenforce 1 || ! sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config; then
        log_error "Failed to configure SELinux."
        return 1
    fi
}

# Function to create a new user with sudo privileges
create_sudo_user() {
    confirm_installation "Do you want to create a new user with sudo privileges?" || return 0
    log_info "Creating a new user with sudo privileges..."
    local username
    read -p "Enter the new username: " username
    if [[ -z "$username" ]]; then
        log_error "Username cannot be empty."
        return 1
    fi
    if ! sudo adduser "$username" || ! sudo passwd "$username" || ! sudo usermod -aG wheel "$username"; then
        log_error "Failed to create user and assign sudo privileges."
        return 1
    fi
}

# Function to disable root SSH login
disable_root_ssh_login() {
    confirm_installation "Do you want to disable root SSH login?" || return 0
    log_info "Disabling root SSH login..."
    if ! sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config || ! sudo systemctl restart sshd; then
        log_error "Failed to disable root SSH login."
        return 1
    fi
}

# Function to install Fail2Ban
install_fail2ban() {
    confirm_installation "Do you want to install Fail2Ban?" || return 0
    log_info "Installing Fail2Ban..."
    if ! sudo dnf install fail2ban -y || ! sudo systemctl enable fail2ban || ! sudo systemctl start fail2ban; then
        log_error "Failed to install and enable Fail2Ban."
        return 1
    fi
}

# Function to optimize system performance
optimize_system_performance() {
    confirm_installation "Do you want to optimize system performance?" || return 0
    log_info "Optimizing system performance..."
    if ! sudo sysctl vm.swappiness=10 || ! echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf; then
        log_error "Failed to optimize system performance."
        return 1
    fi
}

# Function to configure time synchronization
configure_time_sync() {
    confirm_installation "Do you want to configure time synchronization?" || return 0
    log_info "Configuring time synchronization..."
    if ! sudo dnf install chrony -y || ! sudo systemctl enable chronyd || ! sudo systemctl start chronyd; then
        log_error "Failed to configure time synchronization."
        return 1
    fi
}

# Function to set up automatic updates
setup_automatic_updates() {
    confirm_installation "Do you want to set up automatic updates?" || return 0
    log_info "Setting up automatic updates..."
    if ! sudo dnf install dnf-automatic -y || ! sudo systemctl enable --now dnf-automatic.timer; then
        log_error "Failed to enable automatic updates."
        return 1
    fi
}

# Function to secure SSH server
secure_ssh_server() {
    confirm_installation "Do you want to secure the SSH server?" || return 0
    log_info "Securing SSH server..."
    if ! sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config || \
       ! sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || \
       ! sudo systemctl restart sshd; then
        log_error "Failed to secure SSH server."
        return 1
    fi
}

# Function to install X11 (RPM)
install_x11() {
    confirm_installation "Do you want to install X11?" || return 0
    log_info "Installing X11..."
    if ! sudo dnf install xorg-x11-server-Xorg xorg-x11-xauth -y; then
        log_error "Failed to install X11."
        return 1
    fi
}

# Function to install KDE with LightDM
install_kde() {
    confirm_installation "Do you want to install KDE with LightDM?" || return 0
    log_info "Installing KDE and LightDM..."
    if ! sudo dnf install plasma-desktop kscreen lightdm lightdm-gtk-greeter kde-gtk-config dolphin konsole kate plasma-discover rocky-backgrounds -y; then
        log_error "Failed to install KDE and LightDM."
        return 1
    fi
}

# Function to set LightDM as the default display manager
set_kde_environment() {
    confirm_installation "Do you want to set LightDM as the default display manager?" || return 0
    log_info "Setting LightDM as the default display manager..."
    if ! sudo systemctl set-default graphical.target || ! sudo systemctl enable lightdm; then
        log_error "Failed to set LightDM as the default display manager."
        return 1
    fi
}

# Function to install Virt-Manager (RPM)
install_virt_manager() {
    confirm_installation "Do you want to install Virt-Manager?" || return 0
    log_info "Installing Virt-Manager..."
    if ! sudo dnf install virt-manager qemu-kvm libvirt libvirt-client virt-install virt-viewer -y; then
        log_error "Failed to install Virt-Manager."
        return 1
    fi

    log_info "Starting and enabling libvirtd service..."
    if ! sudo systemctl enable --now libvirtd; then
        log_error "Failed to enable libvirtd service."
        return 1
    fi

    log_info "Adding the current user to the libvirt group..."
    if ! sudo usermod -aG libvirt "$(whoami)"; then
        log_error "Failed to add user to libvirt group."
        return 1
    fi

    log_info "Configuring Polkit for user session permissions..."
    if ! sudo bash -c 'cat > /etc/polkit-1/rules.d/80-libvirt-manage.rules' << EOF
// Allow users in the 'libvirt' group to manage libvirt
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("libvirt")) {
        return polkit.Result.YES;
    }
});
EOF
    then
        log_error "Failed to configure Polkit for libvirt permissions."
        return 1
    fi
}

# Function to install Flatpak and add Flathub repository
install_flatpak() {
    confirm_installation "Do you want to install Flatpak and add Flathub repository?" || return 0
    log_info "Installing Flatpak..."
    if ! sudo dnf install flatpak -y; then
        log_error "Failed to install Flatpak."
        return 1
    fi

    log_info "Adding Flathub repository..."
    if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_error "Failed to add Flathub repository."
        return 1
    fi
}

# Function to install Brave Browser via Flatpak
install_brave_browser() {
    confirm_installation "Do you want to install Brave Browser?" || return 0
    install_flatpak_app "com.brave.Browser"
}

# Function to install OBS Studio (RPM)
install_obs_studio() {
    confirm_installation "Do you want to install OBS Studio?" || return 0
    log_info "Installing OBS Studio..."
    if ! sudo dnf install obs-studio -y; then
        log_error "Failed to install OBS Studio."
        return 1
    fi
}

# Function to install multimedia codecs via Flatpak
install_multimedia_codecs() {
    confirm_installation "Do you want to install multimedia codecs?" || return 0
    install_flatpak_app "org.freedesktop.Platform.ffmpeg-full"
}

# Function to install media players via Flatpak
install_media_players() {
    confirm_installation "Do you want to install VLC and MPV media players?" || return 0
    install_flatpak_app "org.videolan.VLC" && install_flatpak_app "io.mpv.Mpv"
}

# Function to install AppImageLauncher via Flatpak
install_appimagelauncher() {
    confirm_installation "Do you want to install AppImageLauncher?" || return 0
    install_flatpak_app "io.github.AppImageLauncher"
}

# Function to install GParted via Flatpak
install_gparted() {
    confirm_installation "Do you want to install GParted?" || return 0
    install_flatpak_app "org.gnome.gparted"
}

# Function to install Transmission via Flatpak
install_transmission() {
    confirm_installation "Do you want to install Transmission?" || return 0
    install_flatpak_app "com.transmissionbt.Transmission"
}

# Main function
main() {
    log_info "Starting the after-install script for Rocky Linux 9.4..."

    update_system || { log_error "System update failed, aborting."; exit 1; }

    install_epel || { log_error "EPEL installation failed, aborting."; exit 1; }

    install_essential_tools || { log_error "Essential tools installation failed, aborting."; exit 1; }

    configure_firewall || { log_error "Firewall configuration failed, aborting."; exit 1; }

    setup_selinux || { log_error "SELinux setup failed, aborting."; exit 1; }

    create_sudo_user || { log_error "User creation failed, aborting."; exit 1; }

    disable_root_ssh_login || { log_error "Disabling root SSH login failed, aborting."; exit 1; }

    install_fail2ban || { log_error "Fail2Ban installation failed, aborting."; exit 1; }

    optimize_system_performance || { log_error "System performance optimization failed, aborting."; exit 1; }

    configure_time_sync || { log_error "Time synchronization configuration failed, aborting."; exit 1; }

    setup_automatic_updates || { log_error "Automatic updates setup failed, aborting."; exit 1; }

    secure_ssh_server || { log_error "SSH server security configuration failed, aborting."; exit 1; }

    install_x11 || { log_error "X11 installation failed, aborting."; exit 1; }

    install_kde || { log_error "KDE installation failed, aborting."; exit 1; }

    set_kde_environment || { log_error "Failed to configure KDE environment, aborting."; exit 1; }

    install_virt_manager || { log_error "Virt-Manager installation failed, aborting."; exit 1; }

    install_flatpak || { log_error "Flatpak installation failed, aborting."; exit 1; }

    install_brave_browser || { log_error "Brave Browser installation failed, aborting."; exit 1; }

    install_obs_studio || { log_error "OBS Studio installation failed, aborting."; exit 1; }

    install_multimedia_codecs || { log_error "Multimedia codecs installation failed, aborting."; exit 1; }

    install_media_players || { log_error "Media players installation failed, aborting."; exit 1; }

    install_appimagelauncher || { log_error "AppImageLauncher installation failed, aborting."; exit 1; }

    install_gparted || { log_error "GParted installation failed, aborting."; exit 1; }

    install_transmission || { log_error "Transmission installation failed, aborting."; exit 1; }

    if [[ "$REBOOT_REQUIRED" == true ]]; then
        log_info "Reboot required to apply updates. Press Enter to reboot your system..."
        read
        sudo reboot
    else
        log_info "Installation completed successfully without the need for a reboot."
    fi
}

# Execute the main function
main
