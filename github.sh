#!/bin/bash

# Install Git
read -r -p "Do you want to install Git? (y/n) " response
if [[ "$response" =~ ^[yY]$ ]]; then
  echo "Installing Git..."
  sudo dnf install git -y
fi
# Set your email address
name="aarjaycreation"
email="aarjaycreation@gmail.com"

git config --global user.name "$name"
git config --global user.email "$email"

# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "$email"

# Print the public key to the console
echo "Your public key is:"
cat ~/.ssh/id_ed25519.pub

# Add the public key to your GitHub account
echo "Copy the public key above and add it to your GitHub account settings."
echo "You can find instructions here: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent"

# Add the private key to the SSH agent (optional)
# This allows you to use the key without entering your passphrase every time
# ssh-add ~/.ssh/id_ed25519

echo "GitHub key generation and printing completed!"
