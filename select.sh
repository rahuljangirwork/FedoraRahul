#!/bin/bash

# Function to print messages in light green for success
function success {
    echo -e "\e[92m$1\e[0m"
}

# Function to print messages in light red for error
function error {
    echo -e "\e[91m$1\e[0m"
}

# Function to print messages in light yellow for information
function info {
    echo -e "\e[93m$1\e[0m"
}

# Function to check if the script is run as root
checkRoot() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root."
        exit 1
    fi
}

# Function definitions for each task
updateSystem() { success "Starting system update..."; sudo dnf update -y && success "System update completed successfully." || error "System update failed."; }
configureDNF() { success "Configuring DNF..."; DNF_CONF="/etc/dnf/dnf.conf"; sudo sed -i 's/^fastestmirror=.*/fastestmirror=True/' $DNF_CONF || echo "fastestmirror=True" | sudo tee -a $DNF_CONF; sudo sed -i 's/^max_parallel_downloads=.*/max_parallel_downloads=10/' $DNF_CONF || echo "max_parallel_downloads=10" | sudo tee -a $DNF_CONF; sudo sed -i 's/^defaultyes=.*/defaultyes=True/' $DNF_CONF || echo "defaultyes=True" | sudo tee -a $DNF_CONF; sudo sed -i 's/^keepcache=.*/keepcache=True/' $DNF_CONF || echo "keepcache=True" | sudo tee -a $DNF_CONF; }
configureYUM() { success "Configuring YUM..."; YUM_CONF="/etc/yum.conf"; sudo sed -i 's/^cachedir=.*/cachedir=\/var\/cache\/yum\/\$basearch\/\$releasever/' $YUM_CONF || echo "cachedir=/var/cache/yum/\$basearch/\$releasever" | sudo tee -a $YUM_CONF; sudo sed -i 's/^keepcache=.*/keepcache=1/' $YUM_CONF || echo "keepcache=1" | sudo tee -a $YUM_CONF; }
enableRepositories() { success "Enabling EPEL and PowerTools repositories..."; sudo dnf install -y epel-release && sudo dnf config-manager --set-enabled crb && success "Repositories enabled successfully." || error "Failed to enable repositories."; }
configureFirewall() { success "Configuring the firewall..."; sudo systemctl enable --now firewalld && sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload && success "Firewall configured successfully." || error "Firewall configuration failed."; }
installSELinuxTools() { success "Installing SELinux management tools..."; sudo dnf install -y policycoreutils-python-utils && success "SELinux tools installed successfully." || error "SELinux tools installation failed."; }
configureAutoUpdates() { success "Configuring automatic security updates..."; sudo dnf install -y dnf-automatic && sudo systemctl enable --now dnf-automatic.timer && success "Automatic security updates configured successfully." || error "Automatic security updates configuration failed."; }
installEPELandRPMFusion() { success "Installing EPEL and RPM Fusion repositories..."; sudo dnf install --nogpgcheck https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm && sudo dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm && success "Repositories installed successfully." || error "Failed to install repositories."; }
disableSSH() { success "Disabling SSH service..."; sudo systemctl stop sshd && sudo systemctl disable sshd && sudo systemctl mask sshd && success "SSH service disabled successfully." || error "Failed to disable SSH service."; }
disableIPv6() { success "Disabling IPv6..."; GRUB_CONF="/etc/default/grub"; grep -q "ipv6.disable=1" $GRUB_CONF && success "IPv6 is already disabled." || echo 'GRUB_CMDLINE_LINUX="ipv6.disable=1"' | sudo tee -a $GRUB_CONF && sudo grub2-mkconfig -o /boot/grub2/grub.cfg && success "IPv6 disabled successfully." && info "Reboot required to apply IPv6 disable changes." || error "Failed to disable IPv6."; }
optimizePerformance() { success "Optimizing system performance..."; sudo dnf install -y tuned && sudo systemctl enable --now tuned && sudo tuned-adm profile throughput-performance && success "System performance optimized successfully." || error "Failed to optimize system performance."; }
setupAutoCleanup() { success "Setting up auto cleanup..."; CRON_FILE="/etc/crontab"; sudo sed -i 's/^clean_requirements_on_remove=.*/clean_requirements_on_remove=True/' $DNF_CONF || echo 'clean_requirements_on_remove=True' | sudo tee -a $DNF_CONF; echo "0 3 * * * /usr/bin/dnf clean all" | sudo tee -a $CRON_FILE && success "Auto cleanup set up successfully." || error "Failed to set up auto cleanup."; }
configureSwap() { RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}'); RAM_MB=$((RAM / 1024)); if [ "$RAM_MB" -lt 8192 ]; then success "System RAM is less than 8GB. Configuring swap..."; ! sudo swapon --show | grep -q "/swapfile" && sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab && success "Swap configured successfully." || success "Swap is already configured."; else success "System RAM is 8GB or more. Swap not configured."; fi }
installFail2Ban() { success "Installing and configuring Fail2Ban..."; sudo dnf install -y fail2ban && sudo systemctl enable --now fail2ban && success "Fail2Ban installed and configured successfully." || error "Failed to install and configure Fail2Ban."; }
installDevTools() { success "Installing development tools..."; sudo dnf groupinstall -y "Development Tools" && success "Development tools installed successfully." || error "Failed to install development tools."; }
cleanupOrphans() { success "Cleaning up orphaned packages..."; sudo dnf autoremove -y && success "Orphaned packages removed successfully." || error "Failed to clean up orphaned packages."; }

# Function names array
functions=("updateSystem" "configureDNF" "configureYUM" "enableRepositories" "configureFirewall" "installSELinuxTools" "configureAutoUpdates" "installEPELandRPMFusion" "disableSSH" "disableIPv6" "optimizePerformance" "setupAutoCleanup" "configureSwap" "installFail2Ban" "installDevTools" "cleanupOrphans")

# Selection array
selected=()

# Function to display the menu
displayMenu() {
    echo "Please choose the tasks you want to run:"
    echo "-----------------------------------------"
    for i in "${!functions[@]}"; do
        echo "$((i+1))) ${functions[i]} [${selected[i]:- }]"
    done
    echo "s) Select All"
    echo "d) Deselect All"
    echo "q) Quit and run selected"
}

# Function to toggle selection
toggleSelection() {
    if [ -z "${selected[$1]}" ]; then
        selected[$1]="x"
    else
        selected[$1]=" "
    fi
}

# Function to select all
selectAll() {
    for i in "${!functions[@]}"; do
        selected[$i]="x"
    done
}

# Function to deselect all
deselectAll() {
    for i in "${!functions[@]}"; do
        selected[$i]=" "
    done
}

# Run selected tasks
runSelectedTasks() {
    for i in "${!functions[@]}"; do
        if [ "${selected[$i]}" = "x" ]; then
            ${functions[$i]}
        fi
    done
}

# Main loop to handle the menu
while true; do
    clear
    displayMenu
    read -rp "Enter choice: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#functions[@]}" ]; then
        toggleSelection $((choice-1))
    elif [[ "$choice" == "s" ]]; then
        selectAll
    elif [[ "$choice" == "d" ]]; then
        deselectAll
    elif [[ "$choice" == "q" ]]; then
        break
    else
        echo "Invalid choice!"
        sleep 1
    fi
done

# Run
