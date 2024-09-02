#!/bin/bash

# Set the log file name based on the script name
LOGFILE="$(dirname "$0")/setup_rocky_linux.log"

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

# 1. System Update
success "Starting system update..."
if sudo dnf update -y >> "$LOGFILE" 2>&1; then
    success "System update completed successfully."
else
    error "System update failed."
    exit 1
fi

# 2. Configure DNF
success "Configuring DNF..."
DNF_CONF="/etc/dnf/dnf.conf"
sudo sed -i 's/^fastestmirror=.*/fastestmirror=True/' $DNF_CONF || echo "fastestmirror=True" | sudo tee -a $DNF_CONF >> "$LOGFILE"
sudo sed -i 's/^max_parallel_downloads=.*/max_parallel_downloads=10/' $DNF_CONF || echo "max_parallel_downloads=10" | sudo tee -a $DNF_CONF >> "$LOGFILE"
sudo sed -i 's/^defaultyes=.*/defaultyes=True/' $DNF_CONF || echo "defaultyes=True" | sudo tee -a $DNF_CONF >> "$LOGFILE"
sudo sed -i 's/^keepcache=.*/keepcache=True/' $DNF_CONF || echo "keepcache=True" | sudo tee -a $DNF_CONF >> "$LOGFILE"

# 3. Configure YUM
success "Configuring YUM..."
YUM_CONF="/etc/yum.conf"
sudo sed -i 's/^cachedir=.*/cachedir=\/var\/cache\/yum\/\$basearch\/\$releasever/' $YUM_CONF || echo "cachedir=/var/cache/yum/\$basearch/\$releasever" | sudo tee -a $YUM_CONF >> "$LOGFILE"
sudo sed -i 's/^keepcache=.*/keepcache=1/' $YUM_CONF || echo "keepcache=1" | sudo tee -a $YUM_CONF >> "$LOGFILE"
# Continue the rest of the YUM configuration similarly...

# 4. Enable EPEL and PowerTools Repositories
success "Enabling EPEL and PowerTools repositories..."
if sudo dnf install -y epel-release >> "$LOGFILE" 2>&1 && sudo dnf config-manager --set-enabled crb >> "$LOGFILE" 2>&1; then
    success "Repositories enabled successfully."
else
    error "Failed to enable repositories."
    exit 1
fi

# 5. Enable and Configure the Firewall
success "Configuring the firewall..."
if sudo systemctl enable --now firewalld >> "$LOGFILE" 2>&1 && sudo firewall-cmd --permanent --add-service=ssh >> "$LOGFILE" 2>&1 && sudo firewall-cmd --reload >> "$LOGFILE" 2>&1; then
    success "Firewall configured successfully."
else
    error "Firewall configuration failed."
    exit 1
fi

# 6. Install SELinux Management Tools
success "Installing SELinux management tools..."
if sudo dnf install -y policycoreutils-python-utils >> "$LOGFILE" 2>&1; then
    success "SELinux tools installed successfully."
else
    error "SELinux tools installation failed."
    exit 1
fi

# 7. Automatic Security Updates
success "Configuring automatic security updates..."
if sudo dnf install -y dnf-automatic >> "$LOGFILE" 2>&1 && sudo systemctl enable --now dnf-automatic.timer >> "$LOGFILE" 2>&1; then
    success "Automatic security updates configured successfully."
else
    error "Automatic security updates configuration failed."
    exit 1
fi

# 8. Install EPEL and RPM Fusion Repositories with nogpgcheck
success "Installing EPEL and RPM Fusion repositories..."
if sudo dnf install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm >> "$LOGFILE" 2>&1 && \
   sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm >> "$LOGFILE" 2>&1; then
    success "Repositories installed successfully."
else
    error "Failed to install repositories."
    exit 1
fi

# 9. Stop the SSH Service
success "Disabling SSH service..."
if sudo systemctl stop sshd >> "$LOGFILE" 2>&1 && sudo systemctl disable sshd >> "$LOGFILE" 2>&1 && sudo systemctl mask sshd >> "$LOGFILE" 2>&1; then
    success "SSH service disabled successfully."
else
    error "Failed to disable SSH service."
    exit 1
fi

# 10. Disable IPv6
success "Disabling IPv6..."
GRUB_CONF="/etc/default/grub"
if grep -q "ipv6.disable=1" $GRUB_CONF; then
    success "IPv6 is already disabled."
else
    echo 'GRUB_CMDLINE_LINUX="ipv6.disable=1"' | sudo tee -a $GRUB_CONF >> "$LOGFILE"
    if sudo grub2-mkconfig -o /boot/grub2/grub.cfg >> "$LOGFILE" 2>&1; then
        success "IPv6 disabled successfully. Please reboot the system to apply the changes."
    else
        error "Failed to disable IPv6."
        exit 1
    fi
fi

# 11. Optimize System Performance
success "Optimizing system performance..."
if sudo dnf install -y tuned >> "$LOGFILE" 2>&1 && sudo systemctl enable --now tuned >> "$LOGFILE" 2>&1 && sudo tuned-adm profile throughput-performance >> "$LOGFILE" 2>&1; then
    success "System performance optimized successfully."
else
    error "Failed to optimize system performance."
    exit 1
fi

# 12. Set Up Auto Cleanup
success "Setting up auto cleanup..."
CRON_FILE="/etc/crontab"
sudo sed -i 's/^clean_requirements_on_remove=.*/clean_requirements_on_remove=True/' $DNF_CONF || echo 'clean_requirements_on_remove=True' | sudo tee -a $DNF_CONF >> "$LOGFILE"
if echo "0 3 * * * /usr/bin/dnf clean all" | sudo tee -a $CRON_FILE >> "$LOGFILE"; then
    success "Auto cleanup set up successfully."
else
    error "Failed to set up auto cleanup."
    exit 1
fi

# 13. Enable Swap if RAM is less than 8 GB
RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_MB=$((RAM / 1024))
if [ "$RAM_MB" -lt 8192 ]; then
    success "System RAM is less than 8GB. Configuring swap..."
    if ! sudo swapon --show | grep -q "/swapfile"; then
        if sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile; then
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
            success "Swap configured successfully."
        else
            error "Failed to configure swap."
            exit 1
        fi
    else
        success "Swap is already configured."
    fi
else
    success "System RAM is 8GB or more. Swap not configured."
fi

# 14. Install and Configure Fail2Ban
success "Installing and configuring Fail2Ban..."
if sudo dnf install -y fail2ban >> "$LOGFILE" 2>&1 && sudo systemctl enable --now fail2ban >> "$LOGFILE" 2>&1; then
    success "Fail2Ban installed and configured successfully."
else
    error "Failed to install and configure Fail2Ban."
    exit 1
fi

# 15. Install Basic Development Tools
success "Installing development tools..."
if sudo dnf groupinstall -y "Development Tools" >> "$LOGFILE" 2>&1; then
    success "Development tools installed successfully."
else
    error "Failed to install development tools."
    exit 1
fi

# 16. Check for Orphaned Packages
success "Cleaning up orphaned packages..."
if sudo dnf autoremove -y >> "$LOGFILE" 2>&1; then
    success "Orphaned packages removed successfully."
else
    error "Failed to clean up orphaned packages."
    exit 1
fi

# Log the end of the script
echo "Script completed at $(date)" >> "$LOGFILE"
success "All tasks completed successfully!"



#Install and Configure Firewall GUI
#Install TLP for Power Management