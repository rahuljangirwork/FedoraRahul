#!/bin/bash

# Define global variables
YUM_CONF="/etc/yum.conf"
DNF_CONF="/etc/dnf/dnf.conf"
SSH_CONFIG="/etc/ssh/sshd_config"
SYSCTL_CONF="/etc/sysctl.conf"
FAIL2BAN_CONFIG="/etc/fail2ban/jail.local"
FIREWALL_SERVICES=("http" "https")

# Logging functions
log_info() {
    printf "[INFO] %s\n" "$1"
}

log_error() {
    printf "[ERROR] %s\n" "$1" >&2
}

# Function to prompt user for confirmation
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

# Function to prompt for SSH port number
ask_for_ssh_port() {
    read -r -p "Enter the SSH port you want to use (default 2222): " SSH_PORT
    SSH_PORT=${SSH_PORT:-2222}
    log_info "Using SSH port: $SSH_PORT"
}

# Function to set up SSH key authentication
setup_ssh_key_authentication() {
    confirm_installation "Do you want to set up SSH key authentication?" || return 0
    log_info "Setting up SSH key authentication..."
    read -r -p "Enter the username for SSH key setup: " username
    if ! sudo mkdir -p /home/$username/.ssh || ! sudo chmod 700 /home/$username/.ssh; then
        log_error "Failed to create .ssh directory."
        return 1
    fi
    read -r -p "Paste your public SSH key: " ssh_key
    if ! echo "$ssh_key" | sudo tee /home/$username/.ssh/authorized_keys > /dev/null || ! sudo chmod 600 /home/$username/.ssh/authorized_keys || ! sudo chown -R "$username:$username" /home/$username/.ssh; then
        log_error "Failed to set up SSH key authentication."
        return 1
    fi
    log_info "SSH key authentication set up for $username."
}

# Function to set up automatic cleanup of logs and package caches
setup_auto_cleanup() {
    confirm_installation "Do you want to set up automatic cleanup of logs and package caches?" || return 0
    log_info "Setting up automatic cleanup..."
    cron_job="0 0 * * * /usr/bin/journalctl --vacuum-time=2weeks && /usr/bin/dnf autoremove -y && /usr/bin/dnf clean all"
    (sudo crontab -l ; echo "$cron_job") | sudo crontab -
    log_info "Automatic cleanup set up."
}

# Function to update the system
update_system() {
    confirm_installation "Do you want to update the system packages?" || return 0
    log_info "Updating system packages..."
    if ! sudo yum update -y; then
        log_error "System update failed."
        return 1
    fi
}

# Function to enable SELinux in enforcing mode
configure_selinux() {
    confirm_installation "Do you want to enable SELinux in enforcing mode?" || return 0
    log_info "Configuring SELinux to enforcing mode..."
    if ! sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config || ! sudo setenforce 1; then
        log_error "Failed to set SELinux to enforcing."
        return 1
    fi
}

# Function to configure firewall
configure_firewall() {
    confirm_installation "Do you want to configure the firewall?" || return 0
    log_info "Configuring firewall..."
    if ! sudo systemctl enable firewalld --now; then
        log_error "Failed to enable firewalld."
        return 1
    fi
    for service in "${FIREWALL_SERVICES[@]}"; do
        if ! sudo firewall-cmd --permanent --add-service="$service"; then
            log_error "Failed to add firewall service $service."
            return 1
        fi
    done
    if ! sudo firewall-cmd --permanent --add-port=${SSH_PORT}/tcp || ! sudo firewall-cmd --permanent --add-icmp-block=echo-request || ! sudo firewall-cmd --reload; then
        log_error "Failed to configure firewall rules."
        return 1
    fi
}

# Function to harden SSH configuration
harden_ssh() {
    confirm_installation "Do you want to harden SSH configuration?" || return 0
    log_info "Hardening SSH configuration..."
    if ! sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG || ! sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' $SSH_CONFIG || ! sudo sed -i "s/^#Port 22/Port ${SSH_PORT}/" $SSH_CONFIG || ! sudo systemctl reload sshd; then
        log_error "Failed to harden SSH configuration."
        return 1
    fi
}

# Function to install and configure Fail2Ban
configure_fail2ban() {
    confirm_installation "Do you want to install and configure Fail2Ban?" || return 0
    log_info "Installing Fail2Ban..."
    
    if ! sudo dnf install -y fail2ban; then
        log_error "Failed to install Fail2Ban."
        return 1
    fi

    log_info "Configuring Fail2Ban..."
    
    # Create or modify the local jail configuration
    if ! sudo bash -c 'cat > /etc/fail2ban/jail.local' << EOF
[DEFAULT]
# Ban hosts for one hour:
bantime = 3600

# Number of failures before banning:
maxretry = 3

# Ignore IPs (whitelist):
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
EOF
    then
        log_error "Failed to configure Fail2Ban."
        return 1
    fi
    
    log_info "Enabling and starting Fail2Ban service..."
    
    if ! sudo systemctl enable --now fail2ban; then
        log_error "Failed to enable and start Fail2Ban."
        return 1
    fi
    
    log_info "Fail2Ban installed and configured successfully."
}


# Function to disable IPv6
disable_ipv6() {
    confirm_installation "Do you want to disable IPv6?" || return 0
    log_info "Disabling IPv6..."
    if ! sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 || ! sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 || ! echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf || ! echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf; then
        log_error "Failed to disable IPv6."
        return 1
    fi
}

# Function to configure sysctl for better security
configure_sysctl() {
    confirm_installation "Do you want to configure sysctl parameters for better security?" || return 0
    log_info "Configuring sysctl parameters..."
    sysctl_config="
# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Enable TCP SYN cookies
net.ipv4.tcp_syncookies = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
"
    if ! echo "$sysctl_config" | sudo tee -a $SYSCTL_CONF || ! sudo sysctl -p; then
        log_error "Failed to apply sysctl settings."
        return 1
    fi
}

# Function to set up automatic updates
setup_automatic_updates() {
    confirm_installation "Do you want to set up automatic updates?" || return 0
    log_info "Setting up automatic updates..."
    if ! sudo dnf install -y dnf-automatic || ! sudo systemctl enable --now dnf-automatic.timer; then
        log_error "Failed to set up automatic updates."
        return 1
    fi
}

# Function to configure and optimize DNF
configure_dnf() {
    confirm_installation "Do you want to configure and optimize DNF?" || return 0
    log_info "Configuring DNF for parallel downloads and performance..."
    if ! grep -q "^max_parallel_downloads=" $DNF_CONF; then
        echo "max_parallel_downloads=10" | sudo tee -a $DNF_CONF
    else
        sudo sed -i 's/^max_parallel_downloads=.*/max_parallel_downloads=10/' $DNF_CONF
    fi

    if ! grep -q "^fastestmirror=" $DNF_CONF; then
        echo "fastestmirror=True" | sudo tee -a $DNF_CONF
    else
        sudo sed -i 's/^fastestmirror=.*/fastestmirror=True/' $DNF_CONF
    fi

    if ! grep -q "^deltarpm=" $DNF_CONF; then
        echo "deltarpm=True" | sudo tee -a $DNF_CONF
    else
        sudo sed -i 's/^deltarpm=.*/deltarpm=True/' $DNF_CONF
    fi

    if ! grep -q "^metadata_timer_sync=" $DNF_CONF; then
        echo "metadata_timer_sync=86400" | sudo tee -a $DNF_CONF
    else
        sudo sed -i 's/^metadata_timer_sync=.*/metadata_timer_sync=86400/' $DNF_CONF
    fi

    if ! grep -q "^defaultyes=" $DNF_CONF; then
        echo "defaultyes=True" | sudo tee -a $DNF_CONF
    else
        sudo sed -i 's/^defaultyes=.*/defaultyes=True/' $DNF_CONF
    fi

    if ! grep -q "^clean_requirements_on_remove=" $DNF_CONF; then
        echo "clean_requirements_on_remove=True" | sudo tee -a $DNF_CONF
    else
        sudo sed -i 's/^clean_requirements_on_remove=.*/clean_requirements_on_remove=True/' $DNF_CONF
    fi

    if ! sudo dnf clean all || ! sudo dnf makecache; then
        log_error "Failed to clean or rebuild DNF cache."
        return 1
    fi
}

# Function to optimize YUM for performance (if applicable)
configure_yum() {
    confirm_installation "Do you want to configure and optimize YUM?" || return 0
    log_info "Configuring YUM for performance..."
    if [[ -f $YUM_CONF ]]; then
        if ! grep -q "^fastestmirror=" $YUM_CONF; then
            echo "fastestmirror=True" | sudo tee -a $YUM_CONF
        else
            sudo sed -i 's/^fastestmirror=.*/fastestmirror=True/' $YUM_CONF
        fi

        if ! grep -q "^deltarpm=" $YUM_CONF; then
            echo "deltarpm=True" | sudo tee -a $YUM_CONF
        else
            sudo sed -i 's/^deltarpm=.*/deltarpm=True/' $YUM_CONF
        fi

        if ! sudo yum clean all || ! sudo yum makecache; then
            log_error "Failed to clean or rebuild YUM cache."
            return 1
        fi
    else
        log_info "YUM configuration file not found. Skipping YUM optimization."
    fi
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

# Function to disable root SSH login
disable_root_ssh_login() {
    confirm_installation "Do you want to disable root SSH login?" || return 0
    log_info "Disabling root SSH login..."
    
    # Modify the PermitRootLogin setting, ensuring the line exists
    if grep -q "^PermitRootLogin" $SSH_CONFIG; then
        if ! sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG; then
            log_error "Failed to modify PermitRootLogin setting."
            return 1
        fi
    else
        if ! sudo bash -c "echo 'PermitRootLogin no' >> $SSH_CONFIG"; then
            log_error "Failed to add PermitRootLogin setting."
            return 1
        fi
    fi

    # Restart SSH service to apply changes
    if ! sudo systemctl restart sshd; then
        log_error "Failed to restart SSH service."
        return 1
    fi
    
    log_info "Root SSH login disabled."
}


# Function to optimize system performance
optimize_system_performance() {
    confirm_installation "Do you want to optimize system performance?" || return 0
    log_info "Optimizing system performance..."
    if ! sudo sysctl vm.swappiness=10 || ! echo "vm.swappiness = 10" | sudo tee -a $SYSCTL_CONF; then
        log_error "Failed to optimize system performance."
        return 1
    fi
}

# Main function
main() {
    ask_for_ssh_port
    update_system
    configure_selinux
    configure_sysctl
    configure_firewall
    harden_ssh
    configure_fail2ban
    disable_ipv6
    configure_dnf
    configure_yum
    setup_automatic_updates
    install_epel
    install_essential_tools
    disable_root_ssh_login
    optimize_system_performance
    setup_ssh_key_authentication
    setup_auto_cleanup
    log_info "System secured and optimized for stability and performance."
}

# Execute main function
main "$@"
