#!/bin/bash

# Function to print messages in green for success
function success {
    echo -e "\e[32m$1\e[0m"
}

# Function to print messages in red for error
function error {
    echo -e "\e[31m$1\e[0m"
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root."
    exit 1
fi

# 1. System Update
success "Starting system update..."
if sudo dnf update -y; then
    success "System update completed successfully."
else
    error "System update failed."
    exit 1
fi

# 2. Configure DNF
success "Configuring DNF..."
DNF_CONF="/etc/dnf/dnf.conf"
if sudo sed -i '/^fastestmirror=/d;/^max_parallel_downloads=/d;/^defaultyes=/d;/^keepcache=/d' $DNF_CONF && \
   echo -e "fastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True" | sudo tee -a $DNF_CONF; then
    success "DNF configuration updated successfully."
else
    error "DNF configuration failed."
    exit 1
fi

# 3. Configure YUM
success "Configuring YUM..."
YUM_CONF="/etc/yum.conf"
if sudo sed -i '/^cachedir=/d;/^keepcache=/d;/^debuglevel=/d;/^logfile=/d;/^exactarch=/d;/^obsoletes=/d;/^gpgcheck=/d;/^plugins=/d;/^installonly_limit=/d;/^clean_requirements_on_remove=/d' $YUM_CONF && \
   echo -e "cachedir=/var/cache/yum/\$basearch/\$releasever\nkeepcache=1\ndebuglevel=2\nlogfile=/var/log/yum.log\nexactarch=1\nobsoletes=1\ngpgcheck=1\nplugins=1\ninstallonly_limit=5\nclean_requirements_on_remove=True" | sudo tee -a $YUM_CONF; then
    success "YUM configuration updated successfully."
else
    error "YUM configuration failed."
    exit 1
fi

# 4. Enable EPEL and PowerTools Repositories
success "Enabling EPEL and PowerTools repositories..."
if sudo dnf install -y epel-release && sudo dnf config-manager --set-enabled crb; then
    success "Repositories enabled successfully."
else
    error "Failed to enable repositories."
    exit 1
fi

# 5. Enable and Configure the Firewall
success "Configuring the firewall..."
if sudo systemctl enable --now firewalld && sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload; then
    success "Firewall configured successfully."
else
    error "Firewall configuration failed."
    exit 1
fi

# 6. Install SELinux Management Tools
success "Installing SELinux management tools..."
if sudo dnf install -y policycoreutils-python-utils; then
    success "SELinux tools installed successfully."
else
    error "SELinux tools installation failed."
    exit 1
fi

# 7. Automatic Security Updates
success "Configuring automatic security updates..."
if sudo dnf install -y dnf-automatic && sudo systemctl enable --now dnf-automatic.timer; then
    success "Automatic security updates configured successfully."
else
    error "Automatic security updates configuration failed."
    exit 1
fi

# 8. Install EPEL and RPM Fusion Repositories with nogpgcheck
success "Installing EPEL and RPM Fusion repositories..."
if sudo dnf install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm && \
   sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm; then
    success "Repositories installed successfully."
else
    error "Failed to install repositories."
    exit 1
fi

# 9. Stop the SSH Service
success "Disabling SSH service..."
if sudo systemctl stop sshd && sudo systemctl disable sshd && sudo systemctl mask sshd; then
    success "SSH service disabled successfully."
else
    error "Failed to disable SSH service."
    exit 1
fi

# 10. Disable IPv6
success "Disabling IPv6..."
GRUB_CONF="/etc/default/grub"
if sudo sed -i '/^GRUB_CMDLINE_LINUX=/d' $GRUB_CONF && \
   echo 'GRUB_CMDLINE_LINUX="ipv6.disable=1"' | sudo tee -a $GRUB_CONF && \
   sudo grub2-mkconfig -o /boot/grub2/grub.cfg && sudo reboot; then
    success "IPv6 disabled successfully."
else
    error "Failed to disable IPv6."
    exit 1
fi

# 11. Optimize System Performance
success "Optimizing system performance..."
if sudo dnf install -y tuned && sudo systemctl enable --now tuned && sudo tuned-adm profile throughput-performance; then
    success "System performance optimized successfully."
else
    error "Failed to optimize system performance."
    exit 1
fi

# 12. Set Up Auto Cleanup
success "Setting up auto cleanup..."
CRON_FILE="/etc/crontab"
if sudo sed -i '/^clean_requirements_on_remove=/d' $DNF_CONF && \
   echo 'clean_requirements_on_remove=True' | sudo tee -a $DNF_CONF && \
   echo "0 3 * * * /usr/bin/dnf clean all" | sudo tee -a $CRON_FILE; then
    success "Auto cleanup set up successfully."
else
    error "Failed to set up auto cleanup."
    exit 1
fi

success "All tasks completed successfully!"
