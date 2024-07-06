#!/bin/bash

# Function to check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Update package lists
apk update

# Install jq if not already installed
if command_exists jq; then
  echo "jq is already installed."
else
  echo "Installing jq..."
  apk add --no-cache jq
fi

# Create necessary files if they don't exist
touch /app/files/urls.txt
touch /app/files/digests.txt

# Make the script.sh script executable
chmod +x /app/script.sh

