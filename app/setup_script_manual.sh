#!/bin/bash


# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Update package lists
sudo apt-get update

# Install jq if not already installed
if command_exists jq; then
  echo "jq is already installed."
else
  echo "Installing jq..."
  sudo apt-get install -y jq
fi

# Install Docker if not already installed
if command_exists docker; then
  echo "Docker is already installed."
else
  echo "Installing Docker..."
  sudo apt-get install -y docker.io
  # Enable and start Docker service
  sudo systemctl enable docker
  sudo systemctl start docker
fi

# Enable and start Docker service
# sudo systemctl enable docker
# sudo systemctl start docker

# Create necessary files if they don't exist
SCRIPTDIR="$(dirname "$0")"
touch $SCRIPTDIR/files/urls.txt
touch $SCRIPTDIR/files/digests.txt

# Make the script.sh script executable
chmod +x $SCRIPTDIR/script.sh

# Run the script once
sudo $SCRIPTDIR/script.sh

# Set up cron job
(crontab -l ; echo "0 3 * * * $(pwd)/script.sh") | crontab -
