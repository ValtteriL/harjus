# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-13"
  config.vm.box_version = "202510.26.0"

  # Install base dependencies
  config.vm.provision "shell", name: "install-dependencies", path: "scripts/install-dependencies.sh"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
  end
end
