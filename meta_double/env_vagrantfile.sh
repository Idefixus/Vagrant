# -*- mode: ruby -*-
# vi: set ft=ruby :
# encoding: UTF-8
#ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

Vagrant.configure("2") do |config|
# Check if this even happens
  config.vm.provision "shell", inline: "echo Start the Vagrant Process"
  # Configuration for the ssh process
  config.ssh.username = "vagrant"
  config.ssh.password = "vagrant"
  
  config.vm.define "vulnerable" do |vulnerable|
	vulnerable.vm.box = "$env:VULNERABLE_BOXNAME"
	vulnerable.vm.network "private_network", ip: "$env:IP_VULNERABLE"
	vulnerable.vm.synced_folder "sync/", "$env:PATH_VULNERABLE_SYNC", create: true
	# Main provisioning with shell, maybe also abstract so ansible and docker and so are possible.
	vulnerable.vm.provision "shell", path: "$env:VULNERABLE_PROVISIONING"
	# Additional provisioning
	# <--HOOK--> Hook to replace

  end

  config.vm.define "scanner" do |scanner|
	scanner.vm.box = "$env:SCANNER_BOXNAME"
	scanner.vm.network "private_network", ip: "$env:IP_SCANNER"
	scanner.vm.synced_folder "sync/", "$env:PATH_SCANNER_SYNC", create: true
	scanner.vm.provision "shell", path: "$env:SCANNER_PROVISIONING"
  end
end