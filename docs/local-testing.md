# Testing Ansible Playbook Locally

This guide explains how to test the Edufeed infrastructure playbook on your local Ubuntu Desktop using Virtual Machine Manager.

## Prerequisites

1. Install required packages:
```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y vagrant ansible libvirt-dev

sudo apt-get purge vagrant-libvirt
sudo apt-mark hold vagrant-libvirt
sudo apt-get install -y qemu libvirt-daemon-system libvirt-dev ebtables libguestfs-tools
sudo apt-get install -y vagrant ruby-fog-libvirt
vagrant plugin install vagrant-libvirt
```

2. Install Ansible collections:
```bash
ansible-galaxy install -r requirements.yml
```

## Quick Start

### 1. Start the Test VM

```bash
# Start the VM using Vagrant
vagrant up

# Check VM status
vagrant status
```

### 2. Test Ansible Connection

```bash
# Test connection to the VM
ansible -i inventory-local.yml all -m ping
```

### 3. Deploy Services

```bash
# Deploy all services
ansible-playbook -i inventory-local.yml edufeed.yml

# Deploy specific service
ansible-playbook -i inventory-local.yml edufeed.yml --tags traefik
```

## Accessing Services

After deployment, services will be available at:

- **Traefik Dashboard**: http://localhost:8081
- **HTTP Services**: http://localhost:8080
- **HTTPS Services**: https://localhost:8443

### Local DNS Setup (Optional)

Add these entries to `/etc/hosts`:
```
192.168.56.10 blossom.local.test
192.168.56.10 relay.local.test
```

Then access services directly:
- https://blossom.local.test:8443
- https://relay.local.test:8443

## Managing the Test VM

```bash
# SSH into the VM
vagrant ssh

# Stop the VM
vagrant halt

# Restart the VM
vagrant reload

# Destroy the VM (removes all data)
vagrant destroy
```

## Troubleshooting

### Check Service Status in VM

```bash
vagrant ssh
docker ps
docker logs traefik
docker logs blossom
docker logs relay-rpi
```

### View Ansible Output

```bash
# Run with verbose output
ansible-playbook -i inventory-local.yml edufeed.yml -vvv
```

### Network Issues

If you can't access services, check:
1. VM is running: `vagrant status`
2. Firewall rules: `sudo ufw status`
3. Port forwarding: `vagrant port`

## Alternative: Using Docker Directly

If you prefer to test without a VM:

```bash
# Create a test container
docker run -d --name ansible-test \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -p 8080:80 -p 8443:443 -p 8081:8080 \
  ubuntu:22.04 /sbin/init

# Install SSH in container
docker exec ansible-test apt update
docker exec ansible-test apt install -y openssh-server python3

# Continue with Ansible deployment
```
