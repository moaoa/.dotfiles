#!/bin/bash
set -e

echo "Updating package index and upgrading packages..."
sudo apt-get update && sudo apt-get upgrade -y

#######################################
# Install Git, Neovim, PHP, and MySQL
#######################################
echo "Installing Git, Neovim, PHP, and MySQL..."
sudo apt-get install -y git neovim php mysql-server

#######################################
# Install Node.js and npm
#######################################
echo "Installing Node.js and npm..."
# This uses the NodeSource repository to get a recent Node.js version (16.x in this example)
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node -v
npm -v

#######################################
# Install Composer
#######################################
echo "Installing Composer..."
EXPECTED_CHECKSUM="$(php -r 'copy(\"https://composer.github.io/installer.sig\", \"php://stdout\");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r \"echo hash_file('sha384', 'composer-setup.php');\")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    >&2 echo "ERROR: Invalid installer checksum for Composer"
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
rm composer-setup.php
sudo mv composer.phar /usr/local/bin/composer

# Verify Composer installation
composer --version

#######################################
# Install Laravel Installer globally
#######################################
echo "Installing Laravel Installer via Composer..."
composer global require laravel/installer

# Add Composer's global vendor bin to PATH (check common locations)
if [ -d "$HOME/.config/composer/vendor/bin" ]; then
  COMPOSER_BIN_DIR="$HOME/.config/composer/vendor/bin"
else
  COMPOSER_BIN_DIR="$HOME/.composer/vendor/bin"
fi

if ! grep -q "$COMPOSER_BIN_DIR" "$HOME/.bashrc"; then
  echo "export PATH=\"\$PATH:$COMPOSER_BIN_DIR\"" >> "$HOME/.bashrc"
  export PATH="$PATH:$COMPOSER_BIN_DIR"
fi

#######################################
# Install Docker
#######################################
echo "Installing Docker..."

# Remove any old Docker versions if they exist
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

# Install packages required for Docker's repository
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index and install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add current user to the Docker group (you might need to log out and log back in)
sudo usermod -aG docker $USER

#######################################
# Install zoxide
#######################################
echo "Installing zoxide..."
if ! sudo apt-get install -y zoxide; then
  # Fallback: if zoxide isn't available via apt, try installing with Cargo (Rust's package manager)
  if command -v cargo >/dev/null 2>&1; then
    cargo install zoxide
  else
    echo "zoxide installation failed and Cargo is not installed. Please install zoxide manually."
  fi
fi

echo "All dependencies have been installed."
echo "Note: For Docker group changes and Composer PATH updates to take effect, log out and log back in or restart your terminal."

