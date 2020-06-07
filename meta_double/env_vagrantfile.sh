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
	
	if $env:monitoring  == 1
		vulnerable.vm.provision "file", source: "../../twpol.txt", destination: "/home/vagrant/"
		vulnerable.vm.provision "shell", path: "../../tripwire_init.sh"
		# Before destroying the machine get the reports - INFO: The remote script has to end with an echo or sth or it will fail.
		vulnerable.trigger.before :destroy do |trigger|
			trigger.warn = "Checking tripwire against the baseline for differences"
			trigger.run_remote = {inline: "tripwire --check > /vagrant/tripwire_log.txt; echo 'Tripwire log copied'"}
			#trigger.run_remote = {inline: "bash -c 'tripwire --check > /vagrant/tripwire_log.txt'"}
		end
	end
	if $env:performance  == 1
		vulnerable.vm.provision "file", source: "../../nmonchart", destination: "/home/vagrant/"
		vulnerable.vm.provision "shell", path: "../../nmon.sh"
		# Before destroying the machine get the nmonchart html file
		vulnerable.trigger.before :destroy do |trigger|
			trigger.warn = "Creating a html chart of the nmon results"
			# Creating the chart and copying the files to the results folder for persistence
			trigger.run_remote = {inline: "ksh nmonchart performance_result.nmon; mv performance_result.nmon /vagrant/; mv performance_result.html /vagrant/; echo 'Nmon result created and copied'"}
		end
	end
  end
  config.vm.define "scanner" do |scanner|
	if $env:wireshark == 1
		scanner.vm.provider 'virtualbox' do |v|  
				# Do a wireshark capture of the traffic - Some machines have the subnet on the first some on the second network interface
			v.customize ['modifyvm', :id, '--nictrace1', 'on']    
			v.customize ['modifyvm', :id, '--nictrace2', 'on'] 	  
			v.customize ['modifyvm', :id, '--nictracefile1', "C:/Users/robin/Desktop/vagrant_projects/meta_double/Scans_20200605T1539572992/20200605T1539573256-ubuntutrusty64-ubuntutrusty64/trace1.pcap"]   
			v.customize ['modifyvm', :id, '--nictracefile2', "C:/Users/robin/Desktop/vagrant_projects/meta_double/Scans_20200605T1539572992/20200605T1539573256-ubuntutrusty64-ubuntutrusty64/trace2.pcap"]   
		end
	end

	scanner.vm.box = "$env:SCANNER_BOXNAME"
	scanner.vm.network "private_network", ip: "$env:IP_SCANNER"
	scanner.vm.synced_folder "sync/", "$env:PATH_SCANNER_SYNC", create: true
	#Openvas automation TODO: Maybe sync whole folder. Handle different provisioning scripts
	scanner.vm.provision "file", source: "../../get_openvas_result.sh", destination: "/home/vagrant/"
	scanner.vm.provision "file", source: "../../openvas_scan_automation_start.sh", destination: "/home/vagrant/"
	# If there is a manuell mode set then dont trigger the custom scan script. But it is copied to the machine.
	if $env:manuell == 0
		scanner.vm.provision "shell", path: "$env:SCANNER_PROVISIONING_FILE_NAME"
	else 
		scanner.vm.provision "file", source: "$env:SCANNER_PROVISIONING_FILE_NAME", destination: "/home/vagrant/"
	end
  end
end