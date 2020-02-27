# Handling Parameters
# Parameter for handling the mode (up or provision, ...)
param (
[String]$mode 
)

[String[]] $scanner_names = "ubuntu/trusty64", "blank", "blank"
[String[]] $vulnerable_names = "rapid7/metasploitable3-ub1404", "ubuntu/trusty64", "blank"
$box_scanner = ""
$box_vulnerable = ""

# User Input function for 3 options
# TODO: Multiple inputs
function Show-Menu
{
     param (
           [string]$Title,
		   [string]$o1,
		   [string]$o2,
		   [string]$o3
     )
     cls
     Write-Host "================ $Title ================"
    
     Write-Host "1: "$o1
     Write-Host "2: "$o2
     Write-Host "3: "$o3
     Write-Host "Q: Press 'Q' to quit."
}

# Wait for user configurations for the scanner

     Show-Menu -Title "Choose your scanner" -o1 $scanner_names[0] -o2 $scanner_names[1] -o3 $scanner_names[2]
     $scanner = Read-Host "Press a key to choose a scanner"
     switch ($scanner)
     {
           '1' {
                cls
                'You chose the ubuntu/trusty64 Scanner'
				$box_scanner = $scanner_names[0]
           } '2' {
                cls
                'You chose option #2'
				$box_scanner = $scanner_names[1]
           } '3' {
                cls
                'You chose option #3'
				$box_scanner = $scanner_names[2]
           } 'q' {
                return
           }
     }
     pause

# Wait for user configurations for the vulnerable

     Show-Menu -Title "Choose your vulnerable" -o1 $vulnerable_names[0] -o2 $vulnerable_names[1] -o3 $vulnerable_names[2]
     $vulnerable = Read-Host "Press a key to choose a vulnerable"
     switch ($vulnerable)
     {
           '1' {
                cls
                'You chose the ubuntu/trusty64 Vulnerable'
				$box_vulnerable = $vulnerable_names[0]
           } '2' {
                cls
                'You chose option #2'
				$box_vulnerable = $vulnerable_names[1]
           } '3' {
                cls
                'You chose option #3'
				$box_vulnerable = $vulnerable_names[2]
           } 'q' {
                return
           }
     }
     pause
	 
#Testing Print the env variables

Write-Host $box_vulnerable and $box_scanner were chosen
# Set env variables
$env:SCANNER_BOXNAME = $box_scanner
$env:VULNERABLE_BOXNAME = $box_vulnerable
$env:SCANNER_PROVISIONING = "scanner_provisioning.sh"
$env:VULNERABLE_PROVISIONING = "vulnerable_provisioning.sh"
$env:PATH_VULNERABLE_SYNC = "/home/vagrant"
$env:PATH_SCANNER_SYNC = "/home/vagrant"
$env:IP_SCANNER = "172.16.16.2"
$env:IP_VULNERABLE = "172.16.16.3"

# Script for starting vagrant 
Write-Host "Start vagrant process"
$StartMs = (Get-Date).Minute
$vagrantfile_path = Read-Host -Prompt 'Enter Vagrantfile path leave empty if this directory should be taken: '

if ($vagrantfile_path -eq ""){
    echo "true"  
    $ip_scanner = $env:IP_SCANNER
    echo ("The Scanner IP-Address  is: " + $ip_scanner)   
    $ip_vulnerable = $env:IP_VULNERABLE	
	
	# Build the Vagrantfile and set the output encoding to utf8
	$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
	#$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
	Get-Content .\env_vagrantfile.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > Vagrantfile

	# Expand Provisioning files:
	Get-Content .\env_scanner_provisioning.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > $env:SCANNER_PROVISIONING

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
#vagrant destroy --force

Write-Host "Machines destroyed"
