# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "generic/ubuntu2204"
  
  # Configure the VM
  config.vm.define "edufeed-test" do |node|
    node.vm.hostname = "edufeed-test"
    
    # Network configuration
    node.vm.network "private_network", ip: "192.168.56.10"
    
    # Forward ports for services
    node.vm.network "forwarded_port", guest: 80, host: 8080
    node.vm.network "forwarded_port", guest: 443, host: 8443
    node.vm.network "forwarded_port", guest: 8080, host: 8081  # Traefik dashboard
    
    # VM resources
    node.vm.provider "libvirt" do |v|
      v.memory = 4096
      v.cpus = 2
    end
    
    # Also support VirtualBox if needed
    node.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 2
    end
    
    # Provision with basic requirements
    node.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
      
      # Install Docker
      curl -fsSL https://get.docker.com | sh
      usermod -aG docker vagrant
      
      # Install Docker Python library for Ansible
      pip3 install docker
    SHELL
  end
end