# Edufeed Infrastructure

This Ansible project automates the deployment of multiple services for the Edufeed infrastructure using Docker containers managed by Traefik as a reverse proxy. All services are built from their source repositories using Docker.

## Services Included

1. **Traefik** - Modern reverse proxy and load balancer with automatic SSL/TLS certificates
2. **Blossom Server** - A Nostr-based media hosting server (built from source)
3. **Strfry** - A high-performance Nostr relay (built from source)

## Prerequisites

- Ansible 2.9 or higher installed on your local machine
- Python 3.x with pip
- Target server(s) running Ubuntu/Debian with:
  - SSH access
  - sudo privileges
  - Docker installed (will be installed automatically if missing)

## Testing Locally

You can test this playbook locally using Vagrant with libvirt (Virtual Machine Manager). See [docs/local-testing.md](docs/local-testing.md) for detailed instructions.

Quick start:
```bash
# Install prerequisites
sudo apt install -y vagrant vagrant-libvirt ansible

# Start test VM
vagrant up

# Deploy services to test VM
ansible-playbook -i inventory-local.yml edufeed.yml
```

## Run it

**Important**: Change the email addresses for letsencrypt. LetsEncrypt won't accept `@example` domains.

### 1. Install Ansible Dependencies

```bash
# Install required Ansible collections
ansible-galaxy install -r requirements.yml
```

### 2. Configure Inventory

Edit the `inventory.yml` file to add your target hosts:

```yaml
all:
  hosts:
    production-server:
      ansible_host: YOUR_SERVER_IP
      ansible_user: YOUR_SSH_USER
      ansible_ssh_private_key_file: ~/.ssh/YOUR_KEY
  
  children:
    docker_hosts:
      hosts:
        production-server:
```

### 3. Customize Variables

You can override default variables in several ways:

#### Option A: Edit inventory variables (recommended for host-specific settings)
Edit the variables in `inventory.yml` under the `docker_hosts` group:

```yaml
docker_hosts:
  vars:
    traefik_acme_email: your-email@example.com
    blossom_domain: blossom.yourdomain.com
    strfry_domain: relay.yourdomain.com
```

#### Option B: Create host-specific variable files
Create a file in `host_vars/production-server.yml`:

```yaml
traefik_acme_email: your-email@example.com
blossom_domain: blossom.yourdomain.com
strfry_domain: relay.yourdomain.com
```

#### Option C: Create group variable files
Create a file in `group_vars/docker_hosts.yml`:

```yaml
# Variables that apply to all docker hosts
traefik_log_level: INFO
```

### 4. Deploy Services

Deploy all services:
```bash
ansible-playbook edufeed.yml
```

Deploy specific services using tags:
```bash
# Deploy only Traefik
ansible-playbook edufeed.yml --tags traefik

# Deploy only Blossom
ansible-playbook edufeed.yml --tags blossom

# Deploy only Strfry
ansible-playbook edufeed.yml --tags strfry
```

Or use individual playbooks:
```bash
# Deploy Traefik
ansible-playbook playbooks/deploy-traefik.yml

# Deploy Blossom
ansible-playbook playbooks/deploy-blossom.yml

# Deploy Strfry
ansible-playbook playbooks/deploy-strfry.yml

# Rebuild images from source (interactive)
ansible-playbook playbooks/rebuild-images.yml
```

## Adding New Services

To add a new service to this infrastructure:

### 1. Create a New Role

```bash
# Create role directory structure
mkdir -p roles/myservice/{tasks,templates,defaults,handlers,files}
```

### 2. Define Default Variables

Create `roles/myservice/defaults/main.yml`:

```yaml
---
myservice_image: "myimage:latest"
myservice_container_name: "myservice"
myservice_domain: "myservice.example.com"
myservice_port: 8080
myservice_network_name: "traefik_web"
```

### 3. Create Tasks

Create `roles/myservice/tasks/main.yml`:

```yaml
---
- name: Deploy MyService container
  docker_container:
    name: "{{ myservice_container_name }}"
    image: "{{ myservice_image }}"
    state: started
    restart_policy: always
    networks:
      - name: "{{ myservice_network_name }}"
    labels:
      traefik.enable: "true"
      traefik.docker.network: "{{ myservice_network_name }}"
      traefik.http.services.myservice.loadbalancer.server.port: "{{ myservice_port }}"
      traefik.http.routers.myservice.rule: "Host(`{{ myservice_domain }}`)"
      traefik.http.routers.myservice.entrypoints: "web,websecure"
      traefik.http.routers.myservice.tls.certresolver: "myresolver"
```

### 4. Add to Main Playbook

Edit `edufeed.yml` to include your new role:

```yaml
- name: Deploy MyService
  include_role:
    name: myservice
  tags:
    - myservice
```

### 5. Create Individual Playbook (Optional)

Create `playbooks/deploy-myservice.yml`:

```yaml
---
- name: Deploy MyService only
  hosts: docker_hosts
  become: yes
  
  roles:
    - myservice
```

## Available Variables

### Traefik Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_version` | `v3` | Traefik version |
| `traefik_acme_email` | `mail@edufeed.org` | Email for Let's Encrypt |
| `traefik_dashboard_enabled` | `true` | Enable Traefik dashboard |
| `traefik_log_level` | `INFO` | Log level (DEBUG, INFO, WARN, ERROR) |
| `traefik_https_port` | `443` | HTTPS port |
| `traefik_http_port` | `80` | HTTP port |
| `traefik_dashboard_port` | `8080` | Dashboard port |

### Blossom Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `blossom_domain` | `blossom.example.com` | Domain for Blossom server |
| `blossom_git_repo` | `https://github.com/hzrd149/blossom-server` | Git repository URL |
| `blossom_git_branch` | `master` | Git branch to build |
| `blossom_port` | `3000` | Internal port |
| `blossom_debug_enabled` | `false` | Enable debug logging |
| `blossom_force_rebuild` | `false` | Force rebuild of Docker image |

### Strfry Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `strfry_domain` | `relay.example.com` | Domain for Nostr relay |
| `strfry_git_repo` | `https://github.com/hoytech/strfry` | Git repository URL |
| `strfry_git_branch` | `master` | Git branch to build |
| `strfry_dockerfile` | `Dockerfile` | Dockerfile to use (options: Dockerfile, ubuntu.Dockerfile, arch.Dockerfile) |
| `strfry_port` | `7777` | Internal port |
| `strfry_relay_name` | `My Nostr Relay` | Relay name |
| `strfry_max_connections` | `100` | Maximum connections |
| `strfry_force_rebuild` | `false` | Force rebuild of Docker image |

## Troubleshooting

### Force Rebuild Images

If you need to rebuild the Docker images from source (e.g., to get latest updates):

```bash
# Force rebuild all services
ansible-playbook edufeed.yml -e "blossom_force_rebuild=true strfry_force_rebuild=true"

# Force rebuild specific service
ansible-playbook edufeed.yml --tags blossom -e "blossom_force_rebuild=true"
```

### Check Service Status

```bash
# SSH to your server and check Docker containers
docker ps

# Check logs for a specific service
docker logs traefik
docker logs blossom
docker logs relay-rpi
```

### Test Ansible Connection

```bash
ansible all -m ping
```

### Dry Run

Test your playbook without making changes:

```bash
ansible-playbook edufeed.yml --check
```

### Verbose Output

For debugging:

```bash
ansible-playbook edufeed.yml -vvv
```

## Backup and Restore

### Backup Docker Volumes

The services use Docker volumes for persistent data. To backup:

```bash
# On the target server
docker run --rm -v blossom_data:/data -v $(pwd):/backup alpine tar czf /backup/blossom-backup.tar.gz -C /data .
docker run --rm -v strfry_data:/data -v $(pwd):/backup alpine tar czf /backup/strfry-data-backup.tar.gz -C /data .
docker run --rm -v strfry_db:/data -v $(pwd):/backup alpine tar czf /backup/strfry-db-backup.tar.gz -C /data .
```

### Restore Docker Volumes

```bash
# On the target server
docker run --rm -v blossom_data:/data -v $(pwd):/backup alpine tar xzf /backup/blossom-backup.tar.gz -C /data
docker run --rm -v strfry_data:/data -v $(pwd):/backup alpine tar xzf /backup/strfry-data-backup.tar.gz -C /data
docker run --rm -v strfry_db:/data -v $(pwd):/backup alpine tar xzf /backup/strfry-db-backup.tar.gz -C /data
```

## Security Considerations

1. **SSL/TLS**: Traefik automatically obtains and renews Let's Encrypt certificates
2. **Network Isolation**: Services communicate through the Docker network `traefik_web`
3. **Exposed Ports**: Only Traefik exposes ports 80, 443, and 8080 (dashboard)
4. **Secrets Management**: Consider using Ansible Vault for sensitive data:
   ```bash
   ansible-vault create group_vars/docker_hosts/vault.yml
   ansible-playbook edufeed.yml --ask-vault-pass
   ```

## Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Please check individual service licenses:
- Traefik: MIT License
- Blossom Server: Check repository
- Strfry: Check repository
