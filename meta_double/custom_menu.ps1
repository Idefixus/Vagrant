# Handling Parameters
# Parameter for handling the mode (up or provision, ...)
param (
[String]$mode 
)

[String[]] $scanner_names = "ubuntu/trusty64", "openvas-packer-debian.virtualbox.box", "blank"
[String[]] $vulnerable_names = "rapid7/metasploitable3-ub1404", "ubuntu/trusty64", "hashicorp/precise64"
[String[]] $global:box_scanner = @()
[String[]] $global:box_vulnerable = @()
# Fill the current working directory with the current path
# [String] $global:working_dir = "C:\Users\robin\Desktop\vagrant_projects\meta_double\"
[String] $global:working_dir = $PSScriptRoot
[String] $global:custom_box = "C:\Users\robin\Desktop\packer_projects\packer-templates\bento\builds\openvas-packer-debian.virtualbox.box"

# Show a base menu

function Base-Menu
{
    Write-Host "================ Choose your configurations ================"

    if ($global:box_scanner.Count -eq 0)
    {
        Write-Host "1: Choose a scanner."
    }
    else
    {
        Write-Host "1: Choose another scanner. Currently chosen scanners are "$global:box_scanner
    }
    if ($global:box_vulnerable.Count -eq 0)
    {
        Write-Host "2: Choose a vulnerable."
    }

    else
    {
        Write-Host "2: Choose another vulnerable. Currently chosen vulnerables are "$global:box_vulnerable
    }
    Write-Host "3: Start the scans"
    Write-Host "4: Get the scan-results"
    Write-Host "5: Add a custom scanner box"
	
    $user = Read-Host
   # $user = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp')
    switch ($user){
        '1' {
            Scanner-Menu -Title "Choose your scanner"
        }
        '2' {
            
            Vulnerable-Menu -Title "Choose your vulnerable"
        }
        '3' {
            
            Scan-Start
        }
        '4' {
            
            "Get the scan results (TODO: List all past scans and give the options to view the results)"
        }
		'5' {
			$custom_box = Read-Host -Prompt "Add the link to the custom box or enter "" for the hardcoded version"
			if ($custom_box -eq ""){
				Write-Host "The hardcoded version has been chosen. The path is: $global:custom_box"
			}
			else {
				Write-Host "The new box can be found at $custom_box"
				$global:custom_box = $custom_box
			}
			$name_custom_box = Read-Host -Prompt "Add the name of the new box"
			$type_custom_box = Read-Host -Prompt "Set the mode: Either Scaner Box (type: scanner) or Vulnerable Box (type: vulnerable) or both (type: both) if you want to abort type '' "
			# Finally add the new box
			vagrant box add $global:custom_box --name $name_custom_box
			
			# Add box to scanners list or vulnerable list or both
			if ($type_custom_box -eq "scanner"){
                Write-Host $scanner_names
                Write-Host $name_custom_box				
                $scanner_names += $name_custom_box
                Write-Host $scanner_names
			}
			elseif ($type_custom_box -eq "vulnerable"){
				$vulnerable_names += $custom_box
			}
			elseif ($type_custom_box -eq "both") {
				$scanner_names += $custom_box
				$vulnerable_names += $custom_box
			}
			elseif ($type_custom_box -eq ""){
			Base-Menu
			}
			else{
			Write-Host "There was an error"
			Base-Menu
			}
			
			Write-Host "Added the box: $global:custom_box with the name: $name_custom_box"
			Base-Menu
		}

    }
}

function Scanner-Menu
{
     param (
           [string]$Title
     )
     
     Write-Host "================ $Title ================"
     for ($i=1; $i -le $scanner_names.Count; $i++) {
     Write-Host $i": "$($scanner_names[$i-1])
     }
     Write-Host $($scanner_names.Count+1)": Press $($scanner_names.Count+1) to return to the menu."
     $scanner = Read-Host
   #  $scanner = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp')

        if ([int]$scanner -le $scanner_names.Count -and [int]$scanner -gt -1) {   
            
            "You chose the $($scanner_names[$scanner-1]) scanner"
            $global:box_scanner += $($scanner_names[$scanner-1])
            
            Base-Menu
        }
        elseif ([int]$scanner -eq $($scanner_names.Count+1)){
            
            Base-Menu
        }

        else {
            
            'Enter a valid value'
            Scanner-Menu -Title "Enter another value to choose a scanner"
        }
     
}

function Vulnerable-Menu
{
     param (
           [string]$Title
     )
     
     Write-Host "================ $Title ================"
     for ($i=1; $i -le $vulnerable_names.Count; $i++) {
     Write-Host $i": "$($vulnerable_names[$i-1])
     }
     Write-Host $($vulnerable_names.Count+1)": Press $($vulnerable_names.Count+1) to return to the menu."
     $vulnerable = Read-Host
   #  $vulnerable = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp')

        if ([int]$vulnerable -le $vulnerable_names.Count -and [int]$vulnerable -gt -1) {   
            
            "You chose the $($vulnerable_names[$vulnerable-1]) vulnerable"
            $global:box_vulnerable += $($vulnerable_names[$vulnerable-1])
            
            Base-Menu
        }
        elseif ([int]$vulnerable -eq $($vulnerable_names.Count+1)){
            
            Base-Menu
        }

        else {
            
            'Enter a valid value'
            Vulnerable-Menu -Title "Enter another value to choose a vulnerable"
        }
     
}

function Bootstrap ($current_scanner, $current_vulnerable, $counter)
{
    
    Write-Host $current_vulnerable and $current_scanner were chosen
# Create folder and set new env variables
    Write-Host "Scan Counter: $counter"
    Write-Host "Working dir: "$global:working_dir
    $new_directory = "Scan_$counter"
    $scope_dir = "$global:working_dir\$new_directory"
    Write-Host $scope_dir
    New-Item -ItemType Directory -name $new_directory -Path $global:working_dir
    Write-Host "The new directory $new_directory was created"

    $env:SCANNER_BOXNAME = $current_scanner
    $env:VULNERABLE_BOXNAME = $current_vulnerable
    $env:SCANNER_PROVISIONING = "scanner_provisioning.sh"
    $env:VULNERABLE_PROVISIONING = "vulnerable_provisioning.sh"
    $env:PATH_VULNERABLE_SYNC = "/home/vagrant"
    $env:PATH_SCANNER_SYNC = "/home/vagrant"
    $env:IP_SCANNER = "172.16.16.2"
    $env:IP_VULNERABLE = "172.16.16.3"

# Create Vagrantfiles

 
    Write-Host "Start vagrant process"
    $StartMs = (Get-Date).Minute

    # Build the Vagrantfile and set the output encoding to utf8
	$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    # Get the scripts to expand to the folder
 #   Copy-Item "C:\Wabash\Logfiles\mar1604.log.txt" -Destination "C:\Presentation"

	#$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
	Get-Content $global:working_dir\env_vagrantfile.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$scope_dir\Vagrantfile"

	# Expand Provisioning files:
	Get-Content $global:working_dir\env_scanner_provisioning.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$scope_dir\$env:SCANNER_PROVISIONING"

    # Expand Provisioning files:
	Get-Content $global:working_dir\env_vulnerable_provisioning.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$scope_dir\$env:VULNERABLE_PROVISIONING"

    # Box add & vagrant up

    Set-Location $scope_dir
    vagrant box add $current_vulnerable
    vagrant box add $current_scanner

    vagrant up
    # Destroy the machines for purity and limitation of ssh errors and ip collisions
    vagrant destroy -f
# Create Result folders

# Start scan with right parameters and provisioning scripts

    $EndMs = (Get-Date).Minute
    Write-Host "This script took $($EndMs - $StartMs) minutes to run and now destroys the machines"

}

function Scan-Start
{
    [int] $counter = 1
    Write-Host "Scan started"
    Write-Host "Scanners: $box_scanner"
    Write-Host "Vulnerables: $box_vulnerable"
    # Do the vagrant process

    #Schedule the machines
    if ($global:box_scanner.Count -eq 0){
        Write-Host "You didn't choose a scanner! Choose at least one scanner and one vulnerable to continue"
        Base-Menu
    }
    if ($global:box_vulnerable.Count -eq 0){
        Write-Host "You didn't choose a scanner! Choose at least one scanner and one vulnerable to continue"
        Base-Menu
    }
    elseif ($global:box_scanner.Count -gt 0 -and $global:box_vulnerable.Count -gt 0){
        # Loop over all the combinations and start the processes one after another! TODO: This is blocking: Maybe parallelize but vagrant will block it from happening
        foreach ($objectA in $global:box_scanner){
            #Write-Host "Scanner: $objectA"
            foreach ($objectB in $global:box_vulnerable){
                Write-Host "$objectA and $objectB are excecuted"
                Bootstrap -current_scanner $objectA -current_vulnerable $objectB -counter $counter
                $counter = $counter + 1
            }
        }
    }
    else {
        Write-Host "An error occured, some configurations were false: Please restart"
        Base-Menu
    }

    Write-Host "Machines have to be destroyed"
}

# Start up the Base-Menu

Base-Menu