#!/bin/bash
# Test deployment script

set -e

echo "=== Testing Edufeed Infrastructure Deployment ==="
echo

# Check if VM is running
if ! vagrant status | grep -q "running"; then
    echo "Starting Vagrant VM..."
    vagrant up
    echo "Waiting for VM to be ready..."
    sleep 10
fi

# Test connection
echo "Testing Ansible connection..."
ansible -i inventory-local.yml all -m ping

# Run syntax check
echo "Running syntax check..."
ansible-playbook -i inventory-local.yml edufeed.yml --syntax-check

# Deploy services
echo "Deploying services..."
ansible-playbook -i inventory-local.yml edufeed.yml

echo
echo "=== Deployment Complete ==="
echo
echo "Services should be accessible at:"
echo "- Traefik Dashboard: http://localhost:8081"
echo "- HTTP: http://localhost:8080" 
echo "- HTTPS: https://localhost:8443"
echo
echo "To check service status, run: vagrant ssh -c 'docker ps'"
