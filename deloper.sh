#!/bin/bash

# Set the log file name based on the script name
LOGFILE="$(dirname "$0")/setup_developer_desktop.log"

# Function to print messages in green for success
function success {
    echo -e "\e[32m$1\e[0m"
    echo "$1" >> "$LOGFILE"
}

# Function to print messages in red for error
function error {
    echo -e "\e[31m$1\e[0m"
    echo "$1" >> "$LOGFILE"
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root."
    exit 1
fi

# Log the start of the script
echo "Script started at $(date)" > "$LOGFILE"

# 1. Install and Configure LightDM with KDE Plasma
success "Installing and configuring LightDM with KDE Plasma..."
if sudo dnf install -y lightdm lightdm-gtk >> "$LOGFILE" 2>&1 && \
   sudo systemctl enable lightdm --force >> "$LOGFILE" 2>&1 && \
   sudo systemctl disable gdm >> "$LOGFILE" 2>&1; then
    success "LightDM installed and set as the default display manager."
else
    error "Failed to install and configure LightDM."
    exit 1
fi


# 2. Install KDE Development Tools
success "Installing KDE development tools..."
if sudo dnf install -y kdevelop kate konsole git cmake gdb valgrind >> "$LOGFILE" 2>&1; then
    success "KDE development tools installed successfully."
else
    error "Failed to install KDE development tools."
    exit 1
fi

# 3. Enable KDE Plasma Desktop Effects and Customizations
success "Configuring KDE Plasma desktop effects and customizations..."
kwriteconfig5 --file kwinrc --group Compositing --key Enabled true
kwriteconfig5 --file kwinrc --group Plugins --key "kwin4_effect_zoomEnabled" true
qdbus org.kde.KWin /KWin reconfigure
success "KDE Plasma desktop effects enabled."

# 4. Install Flatpak and Set Up Development Environment
success "Installing Flatpak and setting up development environment..."
if sudo dnf install -y flatpak >> "$LOGFILE" 2>&1; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    success "Flatpak and Flathub repository set up successfully."
    sudo flatpak install -y flathub org.gnome.Builder com.jetbrains.IntelliJ-IDEA-Community
    success "Development tools installed via Flatpak."
else
    error "Failed to install Flatpak."
    exit 1
fi

# 5. Configure KDE Plasma for Maximum Productivity
success "Configuring KDE Plasma for maximum productivity..."
kwriteconfig5 --file kwinrc --group Desktops --key Number 4
kwriteconfig5 --file kwinrc --group Windows --key BorderlessMaximizedWindows true
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch One Desktop Down" "Meta+Down,none,Switch to Next Desktop"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch One Desktop Up" "Meta+Up,none,Switch to Previous Desktop"
qdbus org.kde.KWin /KWin reconfigure
success "KDE Plasma configured for maximum productivity."

# 6. Install and Configure Git with GUI Tools
success "Installing and configuring Git with GUI tools..."
if sudo dnf install -y git gitg git-cola >> "$LOGFILE" 2>&1; then
    success "Git and Git GUI tools installed successfully."
else
    error "Failed to install Git and GUI tools."
    exit 1
fi

# 7. Set Up Node.js and NPM with Node Version Manager (NVM)
success "Installing Node.js and NPM using Node Version Manager (NVM)..."
if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash >> "$LOGFILE" 2>&1; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts >> "$LOGFILE" 2>&1
    success "Node.js and NPM installed successfully with NVM."
else
    error "Failed to install Node.js and NPM."
    exit 1
fi

# 8. Set Up Python and Pip (Python Package Manager)
success "Installing Python and Pip..."
if sudo dnf install -y python3 python3-pip >> "$LOGFILE" 2>&1; then
    success "Python and Pip installed successfully."
else
    error "Failed to install Python and Pip."
    exit 1
fi

# 9. Set Up Virtual Environments for Python Development
success "Setting up Python virtual environment tools..."
if sudo pip3 install virtualenv >> "$LOGFILE" 2>&1; then
    success "Virtualenv installed successfully."
    mkdir -p ~/venvs
    echo 'export WORKON_HOME=~/venvs' >> ~/.bashrc
    echo 'source /usr/local/bin/virtualenvwrapper.sh' >> ~/.bashrc
    source ~/.bashrc
    success "Virtualenv configured successfully."
else
    error "Failed to install Virtualenv."
    exit 1
fi

# 10. Install JDK for Java Development and Set Global Environment Variables
success "Installing JDK..."
if sudo dnf install -y java-11-openjdk-devel >> "$LOGFILE" 2>&1; then
    success "JDK installed successfully."
    echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc
    success "Java environment variables set successfully."
else
    error "Failed to install JDK."
    exit 1
fi

# 11. Install a Code Editor (VS Code)
success "Installing Visual Studio Code..."
if sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
   sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' && \
   sudo dnf install -y code >> "$LOGFILE" 2>&1; then
    success "Visual Studio Code installed successfully."
else
    error "Failed to install Visual Studio Code."
    exit 1
fi

# 12. Configure Git for Your Workflow
success "Configuring Git for your workflow..."
git config --global user.name "aarjaycreation"
git config --global user.email "aarjaycreation@gmail.com"
git config --global color.ui true
git config --global core.editor "code --wait"
git config --global init.defaultBranch master
success "Git configured successfully."

# 13. Install Virt-Manager and Dependencies
success "Installing KVM, QEMU, libvirt, and virt-manager..."
if sudo dnf install -y qemu-kvm libvirt libvirt-devel virt-install virt-manager bridge-utils >> "$LOGFILE" 2>&1; then
    success "KVM, QEMU, libvirt, and virt-manager installed successfully."
    sudo systemctl enable --now libvirtd >> "$LOGFILE" 2>&1
    success "libvirtd service started and enabled."
else
    error "Failed to install KVM, QEMU, libvirt, and virt-manager."
    exit 1
fi

# 14. Add User to libvirt Group
success "Adding user to libvirt group..."
if sudo usermod -aG libvirt "$USER"; then
    success "User added to libvirt group. Log out and log back in for changes to take effect."
else
    error "Failed to add user to libvirt group."
    exit 1
fi

# 15. Install Additional Tools for VM Management
success "Installing additional packages for guest OS support..."
if sudo dnf install -y libguestfs-tools spice-vdagent virt-viewer >> "$LOGFILE" 2>&1; then
    success "Additional packages installed successfully."
else
    error "Failed to install additional packages."
    exit 1
fi

# 16. Install Brave Browser Using Flatpak
success "Installing Brave browser using Flatpak..."
if sudo flatpak install -y flathub com.brave.Browser >> "$LOGFILE" 2>&1; then
    success "Brave browser installed successfully."
else
    error "Failed to install Brave browser."
    exit 1
fi

# 17. Install Transmission for Torrent Links Using Flatpak
success "Installing Transmission for torrent links using Flatpak..."
if sudo flatpak install -y flathub com.transmissionbt.Transmission >> "$LOGFILE" 2>&1; then
    success "Transmission installed successfully."
else
    error "Failed to install Transmission."
    exit 1
fi

# 18. Install Google Chrome Using Flatpak
success "Installing Google Chrome using Flatpak..."
if sudo flatpak install -y flathub com.google.Chrome >> "$LOGFILE" 2>&1; then
    success "Google Chrome installed successfully."
else
    error "Failed to install Google Chrome."
    exit 1
fi

# Log the end of the script
echo "Script completed at $(date)" >> "$LOGFILE"
success "All tasks completed successfully!"
