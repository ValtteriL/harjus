# -*- mode: ruby -*-
# vi: set ft=ruby :

# Resource allocation: 50% of host by default, overridable via environment variables
# VM_CPUS: Number of CPUs to allocate (default: 50% of host CPUs)
# VM_RAM_GB: Amount of RAM in GB to allocate (default: 50% of host RAM)
def get_host_cpus
  case RbConfig::CONFIG['host_os']
  when /darwin/
    `sysctl -n hw.ncpu`.to_i
  when /linux/
    `nproc`.to_i
  else
    2
  end
end

def get_host_memory_gb
  case RbConfig::CONFIG['host_os']
  when /darwin/
    `sysctl -n hw.memsize`.to_i / 1024 / 1024 / 1024
  when /linux/
    `grep MemTotal /proc/meminfo | awk '{print $2}'`.to_i / 1024 / 1024
  else
    4
  end
end

host_cpus = get_host_cpus
host_memory_gb = get_host_memory_gb

vm_cpus = ENV['VM_CPUS'] ? ENV['VM_CPUS'].to_i : (host_cpus / 2)
vm_memory_gb = ENV['VM_RAM_GB'] ? ENV['VM_RAM_GB'].to_i : (host_memory_gb / 2)

# Ensure minimum resources
vm_cpus = [vm_cpus, 1].max
vm_memory_gb = [vm_memory_gb, 1].max

Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "cloud-image/debian-13"
  config.vm.box_version = "20251117.2299.0"

  # Provision development dependencies (build tools, compilers, conan, etc.)
  config.vm.provision "dev", type: "shell", path: "deploy/scripts/provision-dev.sh"

  # Provision runtime dependencies (DPDK, network tools, etc.)
  config.vm.provision "runtime", type: "shell", path: "deploy/scripts/provision-runtime.sh"

  # Sync project directory
  config.vm.synced_folder ".", "/home/vagrant/harjus", type: "virtualbox"

  # Primary network interface (NAT) for control traffic (SSH, etc.) - created by default
  # Second network interface for DPDK
  config.vm.network "public_network", auto_config: false

  # Prepare host for kernel bypass via f-stack
  config.vm.provision "initialize", type: "shell",  
    path: "deploy/scripts/initialize.sh", args: "enp0s8", run: "always"

  # Configure disk size
  config.vm.disk :disk, size: "50GB", primary: true

  # VirtualBox-specific configuration
  config.vm.provider "virtualbox" do |vb|

    vb.cpus = vm_cpus
    vb.memory = vm_memory_gb * 1024
    
    # Set second NIC to Intel E1000 (DPDK-compatible, unlike default PCnet32)
    vb.customize ["modifyvm", :id, "--nictype2", "82540EM"]
    
    # Enable promiscuous mode on second NIC for DPDK
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]

    # Enable nested virtualization
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]

    # Enable IO-APIC to allow multi-core support
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
end
