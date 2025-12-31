# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "cloud-image/debian-13"
  config.vm.box_version = "20251117.2299.0"

  # Provision with provision.sh script
  config.vm.provision "shell", path: "deploy/scripts/provision.sh"

  # Sync project directory
  config.vm.synced_folder ".", "/home/vagrant/harjus", type: "virtualbox"

  # Primary network interface (NAT) for control traffic (SSH, etc.) - created by default
  # Second network interface for DPDK
  config.vm.network "public_network", auto_config: false

  # Prepare host for kernel bypass via f-stack
  config.vm.provision "initialize", type: "shell",  
    path: "deploy/scripts/initialize.sh", run: "always"

  config.vm.provider "virtualbox" do |vb|

    vb.cpus = 22          # 22 CPU cores
    vb.memory = 1024 * 16  # 16 GB RAM
    
    # Enable promiscuous mode on second NIC for DPDK
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

    # Enable nested virtualization
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]

    # Enable IO-APIC to allow multi-core support
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
end
