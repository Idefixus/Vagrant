# -*- mode: ruby -*-
# vi: set ft=ruby :
# encoding: UTF-8

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
	vulnerable.vm.provision "shell", path: "$env:VULNERABLE_PROVISIONING_FILE_NAME"
	
	if $env:monitoring
		vulnerable.vm.provision "file", source: "../twpol.txt", destination: "/home/vagrant/"
		vulnerable.vm.provision "shell", path: "../tripwire_init.sh"
		# Before destroying the machine get the reports - INFO: The remote script has to end with an echo or sth or it will fail.
		vulnerable.trigger.before :destroy do |trigger|
			trigger.warn = "Checking tripwire against the baseline for differences"
			trigger.run_remote = {inline: "tripwire --check > /vagrant/tripwire_log.txt; echo 'Tripwire log copied'"}
			trigger.warn = "Test"
		end
	end
  end
  config.vm.define "scanner" do |scanner|
	scanner.vm.box = "$env:SCANNER_BOXNAME"
	scanner.vm.network "private_network", ip: "$env:IP_SCANNER"
	scanner.vm.synced_folder "sync/", "$env:PATH_SCANNER_SYNC", create: true
	#Openvas automation TODO: Maybe sync whole folder. Handle different provisioning scripts
	scanner.vm.provision "file", source: "../get_openvas_result.sh", destination: "/home/vagrant/"
	scanner.vm.provision "file", source: "../openvas_scan_automation_start.sh", destination: "/home/vagrant/"
	scanner.vm.provision "shell", path: "$env:SCANNER_PROVISIONING_FILE_NAME"
  end
end