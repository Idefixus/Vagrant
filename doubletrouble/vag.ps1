# Handling Parameters
# Parameter for handling the mode (up or provision, ...)
param (
[String]$mode 
)


# Script for starting vagrant 
Write-Host "Start vagrant process"
$StartMs = (Get-Date).Minute
$vagrantfile_path = Read-Host -Prompt 'Enter Vagrantfile path leave empty if this directory should be taken: '

if ($vagrantfile_path -eq ""){
    echo "true"
    $env:IP_SCANNER = "172.16.16.2"
    $ip_scanner = $env:IP_SCANNER

    echo ("The Scanner IP-Address  is: " + $ip_scanner)
    $env:IP_VULNERABLE = "172.16.16.3"
    $ip_vulnerable = $env:IP_VULNERABLE
	if ($mode -eq "up"){
	
    vagrant up
    echo "Vagrant is now upping"
	}
	else {
	vagrant provision
	echo "Vagrant is provisioning"
	}
    
} 
else {
    echo "false"
}

$EndMs = (Get-Date).Minute
Write-Host "This script took $($EndMs - $StartMs) minutes to run and now destroys the machines"

# Close down everything when pipeline is finished
vagrant destroy --force

Write-Host "Machines destroyed"
