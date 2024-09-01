#!/bin/bash

APP_NAME="X11, KDE Plasma, Virt-Manager, Development Tools, and Flatpaks"

echo -e "\033[0;32m====================================="
echo -e "\033[1;32mThe Linux IT Guy - Rocky Linux 9.4 Install Script"
echo -e "\033[1;32mInstalling $APP_NAME"
echo -e "\033[0;32m=====================================\033[0m"

# Function to log info messages
log_info() {
    printf "\033[1;34m[INFO]\033[0m %s\n" "$1"
}

# Function to log error messages and exit
log_error() {
    printf "\033[1;31m[ERROR]\033[0m %s\n" "$1" >&2
    exit 1
}

# Function to prompt the user for confirmation
confirm_installation() {
    read -r -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to enable CRB repository
enable_crb_repo() {
    confirm_installation "Do you want to enable the CRB repository?" || return 0
    log_info "Enabling CRB repository..."
    if ! sudo dnf config-manager --set-enabled crb; then
        log_error "Failed to enable CRB repository."
        return 1
    fi
}

# Function to install Development Tools
install_dev_tools() {
    confirm_installation "Do you want to install Development Tools?" || return 0
    log_info "Installing Development Tools..."
    if ! sudo dnf -y groupinstall "Development Tools"; then
        log_error "Failed to install Development Tools."
        return 1
    fi
}

# Function to install X11
install_x11() {
    confirm_installation "Do you want to install X11?" || return 0
    log_info "Installing X11..."
    if ! sudo dnf install -y xorg-x11-server-Xorg xorg-x11-xauth; then
        log_error "Failed to install X11."
        return 1
    fi
}

# Function to install KDE with LightDM
install_kde() {
    confirm_installation "Do you want to install KDE with LightDM?" || return 0
    log_info "Installing KDE and LightDM..."
    if ! sudo dnf install -y plasma-desktop kscreen lightdm lightdm-gtk-greeter kde-gtk-config dolphin konsole kate plasma-discover rocky-backgrounds; then
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
    if ! sudo dnf install -y virt-manager qemu-kvm libvirt libvirt-client virt-install virt-viewer; then
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

# Function to install and configure Flatpak
install_flatpak() {
    confirm_installation "Do you want to install and configure Flatpak?" || return 0
    log_info "Installing Flatpak..."
    if ! sudo dnf install -y flatpak; then
        log_error "Failed to install Flatpak."
        return 1
    fi

    log_info "Adding Flathub repository..."
    if ! sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log_error "Failed to add Flathub repository."
        return 1
    fi
}

# Function to install applications via Flatpak
install_flatpak_apps() {
    confirm_installation "Do you want to install additional applications via Flatpak?" || return 0
    log_info "Installing applications via Flatpak..."
    flatpak_apps=(
        "com.brave.Browser"             # Brave Browser
        "org.fedoraproject.MediaWriter"  # Fedora Media Writer
        "org.gnome.GParted"              # GParted
        "com.transmissionbt.Transmission" # Transmission (Torrent Client)
        "com.obsproject.Studio"          # OBS Studio
        "io.github.AppImageLauncher"     # AppImageLauncher
    )

    for app in "${flatpak_apps[@]}"; do
        if ! flatpak install -y flathub "$app"; then
            log_error "Failed to install $app via Flatpak."
            return 1
        fi
    done
}

# Main function to execute the installation
main() {
    enable_crb_repo
    install_dev_tools
    install_x11
    install_kde
    set_kde_environment
    install_virt_manager
    install_flatpak
    install_flatpak_apps

    log_info "$APP_NAME has been installed and configured successfully."
    echo -e "\033[1;32mPress Enter to reboot into your new environment...\033[0m"
    read

    if ! sudo reboot; then
        log_error "Failed to reboot the system. Please reboot manually."
    fi
}

# Execute the main function
main "$@"
