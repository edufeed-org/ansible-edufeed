#!/bin/bash
# Setup script for local testing with Vagrant

set -e

echo "=== Edufeed Infrastructure Local Testing Setup ==="
echo

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    echo "Error: This script is designed for Ubuntu/Debian systems."
    exit 1
fi

# Install prerequisites
echo "Installing prerequisites..."
sudo apt update
sudo apt install -y vagrant vagrant-libvirt ansible python3-pip qemu-kvm libvirt-daemon-system

# Add user to libvirt group
echo "Adding user to libvirt group..."
sudo usermod -aG libvirt $USER

# Install Ansible collections
echo "Installing Ansible collections..."
ansible-galaxy install -r requirements.yml

# Create local hosts entry file
echo "Creating local hosts file..."
cat > hosts.local << EOF
# Add these entries to /etc/hosts for local testing
192.168.56.10 blossom.local.test
192.168.56.10 relay.local.test
EOF

echo
echo "=== Setup Complete ==="
echo
echo "Next steps:"
echo "1. Log out and back in for group changes to take effect"
echo "2. Run 'vagrant up' to start the test VM"
echo "3. Run 'ansible-playbook -i inventory-local.yml edufeed.yml' to deploy"
echo
echo "Optional: Add entries from 'hosts.local' to /etc/hosts for local domain access"
echo
