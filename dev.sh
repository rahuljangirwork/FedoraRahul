# Install Node.js and npm using RPM
read -r -p "Do you want to install Node.js and npm using RPM? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing Node.js and npm..."
  sudo dnf install nodejs npm -y
  echo "Node.js and npm installation complete!"
fi

# Install Angular CLI using npm
read -r -p "Do you want to install Angular CLI using npm? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing Angular CLI..."
  sudo npm install -g @angular/cli@latest
  echo "Angular CLI installation complete!"
fi

# Install VS Code (using the official Microsoft yum repository)
read -r -p "Do you want to install VS Code? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Setting up VS Code repository..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

  echo "Installing VS Code..."
  sudo dnf install code -y

  echo "VS Code installation complete!"
fi

