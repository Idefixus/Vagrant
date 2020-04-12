# Handling Parameters
# Parameter for handling the mode (up or provision, ...)
param (
[String]$mode 
)


# Scanner configs: All have to be the same length
[String[]] $global:scanner_names = "ubuntu/trusty64", "openvas-packer-debian.virtualbox.box", "blank"
#[String[]] $global:scanner_config = @(("ubuntu/trusty64", "openvas-packer-debian.virtualbox.box", "blank"),("Ubuntu", "Debian", "unknown"))
$global:scanner_types = "Ubuntu", "Debian", ""


# Vulnerable configs
[String[]] $global:vulnerable_names = "rapid7/metasploitable3-ub1404", "ubuntu/trusty64", "hashicorp/precise64"
#[String[]] $global:vulnerable_config = @(("rapid7/metasploitable3-ub1404", "ubuntu/trusty64", "hashicorp/precise64"),("Ubuntu", "Ubuntu", "Ubuntu"))
$global:vulnerable_types = "Ubuntu", "Ubuntu", "Ubuntu"


[String[]] $global:box_scanner = @()
[String[]] $global:scanner_provisioning = @()
[String[]] $global:box_scanner_types = @()
[String[]] $global:box_vulnerable = @()
[String[]] $global:vulnerable_provisioning = @()
[String[]] $global:box_vulnerable_types = @()
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
    Write-Host "3: Start the scans (and configuration)"
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
            Results-Menu
        }
		'5' {
            # Add a custom box
			$my_custom_box = Read-Host -Prompt "Add the link to the custom box or enter "" for the hardcoded version"
			if ($my_custom_box -eq ""){
				Write-Host "The hardcoded version has been chosen. The path is: $global:custom_box"
			}
			else {
				Write-Host "The new box can be found at $my_custom_box"
				$global:custom_box = $my_custom_box
			}
			$name_custom_box = Read-Host -Prompt "Add the name of the new box"
			$type_custom_box = Read-Host -Prompt "Set the mode: Either Scaner Box (type: scanner) or Vulnerable Box (type: vulnerable) or both (type: both) if you want to abort type '' "
            $boxtype_custom_box = Read-Host -Prompt "What kind of machine is this: Ubuntu, Debian"
			# Finally add the new box
            Write-Host $global:custom_box
            Write-Host $name_custom_box
			vagrant box add $global:custom_box --name $name_custom_box
			
			# Add box to scanners list or vulnerable list or both
			if ($type_custom_box -eq "scanner"){
                Write-Host $global:scanner_names
                Write-Host $name_custom_box				
                $global:scanner_names += $name_custom_box
                Write-Host $global:scanner_names
                # Add scanner config for machine type and provisioning script
                $global:scanner_types += $boxtype_custom_box

			}
			elseif ($type_custom_box -eq "vulnerable"){
				$global:vulnerable_names += $my_custom_box

                # Add vulnerable config for machine type and provisioning script
                $global:vulnerable_types += $boxtype_custom_box
			}
			elseif ($type_custom_box -eq "both") {
				$global:scanner_names += $my_custom_box
				$global:vulnerable_names += $my_custom_box
                # Add vulnerable config for machine type and provisioning script
                $global:vulnerable_types += $boxtype_custom_box
                $global:scanner_types += $boxtype_custom_box

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
# The Results menu
function Results-Menu
{
    $child_names = Get-ChildItem -Path . -Name
    $scanResults = @()
    foreach($child in $child_names){
        $index = [array]::IndexOf($child_names,$child)
        #TODO: Do nicer... I hate arrays
        $index -= 1
        if ($child -match "\b(Scan_[1-9]([0-9])?([0-9])?)\b"){
            $scanResults += $child
            Write-Host "[$index] $child"
        }
    }
    Write-Host $scanResults
    $input = Read-Host -Prompt "Choose a Scan to get the results from."

        Write-Host $scanResults[$input]
        # TODO: Inline doesnt work. Fix it
        $value = $scanResults[$input]
        Invoke-Item -Path ".\$value"

}

# Starts the scanner menu 
function Scanner-Menu
{
     param (
           [string]$Title
     )
     
     Write-Host "================ $Title ================"
     for ($i=1; $i -le $global:scanner_names.Count; $i++) {
     Write-Host $i": "$($global:scanner_names[$i-1])
     }
     Write-Host $($global:scanner_names.Count+1)": Press $($global:scanner_names.Count+1) to return to the menu."
     $scanner = Read-Host
   #  $scanner = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp')

        if ([int]$scanner -le $global:scanner_names.Count -and [int]$scanner -gt -1) {   
            
            Write-Host "You chose the $($global:scanner_names[$scanner-1]) scanner. This is a $($global:scanner_types[$scanner-1])"

            #Choose fitting Scans depending on the machine type.
            $machine_type = $($global:scanner_types[$scanner-1])

            #Set the global variables for the current scan
            $global:box_scanner += $($global:scanner_names[$scanner-1])
            $global:box_scanner_types += $machine_type


            Write-Host "Choose a use-case (scan configuration)"
            if ($machine_type -eq ""){
            Write-Host "You chose a default script"
            } 
            else {
                # TODO: Check type of input
                $fitting_scripts = Get-ChildItem -Path ".\provisioning\$machine_type\*.sh" -Name
                Write-Host "Fitting: "$fitting_scripts
                for ($i=1; $i -le $fitting_scripts.Count; $i++) {
                    Write-Host $i" : "$($fitting_scripts[$i-1])
                }
                [int]$chosen = Read-Host -Prompt "Choose a script"
                $path_custom_scanner_provisioning_script = $($fitting_scripts[$chosen-1])
                Write-Host "The chosen script is: "$path_custom_scanner_provisioning_script

                #Set the chosen script globally for this machine
                Write-Host "Currently editing "$global:scanner_names[$chosen-1]
                $global:scanner_provisioning += $path_custom_scanner_provisioning_script
                Write-Host "Script is set"
            }

            Base-Menu
        }
        elseif ([int]$scanner -eq $($global:scanner_names.Count+1)){
            
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
     for ($i=1; $i -le $global:vulnerable_names.Count; $i++) {
     Write-Host $i": "$($global:vulnerable_names[$i-1])
     }
     Write-Host $($global:vulnerable_names.Count+1)": Press $($global:vulnerable_names.Count+1) to return to the menu."
     $vulnerable = Read-Host
   #  $vulnerable = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyUp')

        if ([int]$vulnerable -le $global:vulnerable_names.Count -and [int]$vulnerable -gt -1) {   
            
            "You chose the $($global:vulnerable_names[$vulnerable-1]) vulnerable"
            $global:box_vulnerable += $($global:vulnerable_names[$vulnerable-1])
            
            ## Add a provisioning script:

            Write-Host "Choose a provisioning script or choose your own"

            $choosable_scripts = Get-ChildItem -Path ".\provisioning\vulnerable_scripts\*.sh" -Name
            Write-Host "Fitting: "$choosable_scripts
                for ($i=1; $i -le $choosable_scripts.Count; $i++) {
                    Write-Host $i" : "$($choosable_scripts[$i-1])
                }
                [int]$chosen = Read-Host -Prompt "Choose a script"
                $path_custom_vulnerable_provisioning_script = $($choosable_scripts[$chosen-1])
                Write-Host "The chosen script is: "$path_custom_vulnerable_provisioning_script

                #Set the chosen script globally for this machine
                Write-Host "Currently editing "$global:vulnerable_names[$chosen-1]
                $global:vulnerable_provisioning += $path_custom_vulnerable_provisioning_script
                Write-Host "Script is set"

                Base-Menu
        }
        elseif ([int]$vulnerable -eq $($global:vulnerable_names.Count+1)){
            
            Base-Menu
        }

        else {
            
            'Enter a valid value'
            Vulnerable-Menu -Title "Enter another value to choose a vulnerable"
        }
     
}

# Bootstrap mechanism for doing a 1S : 1V combination with all current configurations given by the paramters
# TODO: Combine the configugration into an object or external file for better overview
# TODO: Add custom vulnerable script after the combination
function Bootstrap ($current_scanner, $scanner_script, $scanner_type, $current_vulnerable, $vulnerable_script, $counter, $local_dir)
{

    Write-Host $current_vulnerable and $current_scanner were chosen -ForegroundColor Red -BackgroundColor Yellow
    # Create folder and set new env variables
    Write-Host "Scan Counter: $counter"
    Write-Host "Working dir: "$local_dir
    $time = Get-Date -DisplayHint Date -Format FileDateTime
    Write-Host $current_scanner
    $new_scanner_name = $current_scanner.Replace("/","")
    Write-Host $new_scanner_name
    $new_vulnerable_name = $current_vulnerable.Replace("/","")
    Write-Host $new_vulnerable_name
    $new_directory = "$time-$new_scanner_name-$new_vulnerable_name"
    New-Item -ItemType Directory -name $new_directory -Path "$global:working_dir\$local_dir"
    Write-Host "The new directory $new_directory was created" -ForegroundColor Red -BackgroundColor Yellow
    
    $scope_dir = "$global:working_dir\$local_dir\$new_directory"
    Write-Host "New working direcory: "$scope_dir -ForegroundColor Red -BackgroundColor Yellow

    $env:SCANNER_BOXNAME = $current_scanner
    $env:VULNERABLE_BOXNAME = $current_vulnerable
    #$env:SCANNER_PROVISIONING = "..\provisioning\$scanner_type\$scanner_script"
    $env:SCANNER_PROVISIONING_FILE_NAME = "scanner_provisioning.sh"
    #$env:VULNERABLE_PROVISIONING = "vulnerable_provisioning.sh" # TODO: Custom vulnerable script
    $env:VULNERABLE_PROVISIONING_FILE_NAME = "vulnerable_provisioning.sh"
    $env:PATH_VULNERABLE_SYNC = "/vagrant"
    $env:PATH_SCANNER_SYNC = "/vagrant"
    $env:IP_SCANNER = "172.16.16.2"
    $env:IP_VULNERABLE = "172.16.16.3"

# Create Vagrantfiles

 
    Write-Host "Start vagrant process" -ForegroundColor Red -BackgroundColor Yellow
    $StartMs = (Get-Date).Minute

    # Build the Vagrantfile and set the output encoding to utf8
	$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    # Get the scripts to expand to the folder
	Get-Content $global:working_dir\env_vagrantfile.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$scope_dir\Vagrantfile"

	# Expand Provisioning files:
	Get-Content "$global:working_dir\provisioning\$scanner_type\$scanner_script" | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$scope_dir\$env:SCANNER_PROVISIONING_FILE_NAME"

    # Expand Provisioning files:
    # TODO: Custom vulnerable script --> Change like scanner
	Get-Content "$global:working_dir\provisioning\vulnerable_scripts\$vulnerable_script" | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$scope_dir\$env:VULNERABLE_PROVISIONING_FILE_NAME"


    # Box add & vagrant up

    Set-Location $scope_dir
    vagrant box add $current_vulnerable --provider virtualbox
    vagrant box add $current_scanner --provider virtualbox

    # Virtualbox as dependency
    vagrant up

    # Do the scan by hand because of bug: Works now
    #vagrant ssh scanner -c "echo 'Doing scan by hand'"
    #vagrant ssh scanner -c "sudo bash openvas_scan_automation_start.sh $env:IP_VULNERABLE"
    #vagrant ssh scanner -c "ip address > /vagrant/ip_scanner.txt"

    # Destroy the machines for purity and limitation of ssh errors and ip collisions also for triggering the :before destroy scripts
    Write-Host "All machines are being destroyed (some scripts can be triggered during this process so this could take a while before the machines are actually destroyed)" -ForegroundColor Red -BackgroundColor Yellow
    vagrant destroy -f

# Create Result folders

# Start scan with right parameters and provisioning scripts

    $EndMs = (Get-Date).Minute
    Write-Host "This script took $($EndMs - $StartMs) minutes to run and now destroys the machines" -ForegroundColor Red -BackgroundColor Yellow

}

function Scan-Start
{
    [int] $counter = 1

    Write-Host "Scanners: $global:box_scanner" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "Vulnerables: $global:box_vulnerable" -ForegroundColor Red -BackgroundColor Yellow
    # Do the vagrant process

    #Schedule the machines
    if ($global:box_scanner.Count -eq 0){
        Write-Host "You didn't choose a scanner! Choose at least one scanner and one vulnerable to continue" -ForegroundColor Red
        Base-Menu
    }
    if ($global:box_vulnerable.Count -eq 0){
        Write-Host "You didn't choose a scanner! Choose at least one scanner and one vulnerable to continue" -ForegroundColor Red
        Base-Menu
    }
    elseif ($global:box_scanner.Count -gt 0 -and $global:box_vulnerable.Count -gt 0){

        # Global configurations

        Write-Host "Do you want to monitor the differences on the vulnerable machine while scanning?" -ForegroundColor Red -BackgroundColor Yellow
        [String] $monitoring = Read-Host -Prompt "y or n"
        if ($monitoring -eq "y"){
            # TODO: Load the monitoring provisioning script.
            # When monitoring 1 == true set the env variable for the tripwire_init.sh script
            $env:monitoring = 1
            Write-Host "Monitoring: [yes]"


        }

        # Create a subfolder for the scans for persistence
        $time = Get-Date -DisplayHint Date -Format FileDateTime
        New-Item -ItemType Directory -name "Scans_$time" -Path "$global:working_dir"
        $local_dir = "Scans_$time"

        # Loop over all the combinations and start the processes one after another!
        Write-Host "Scan(s) started" -ForegroundColor Red -BackgroundColor Yellow
        #Iterator for the offset of the chosen machines for configurations

        $scanner_iterator = 0
        $vulnerable_iterator = 0
        foreach ($objectA in $global:box_scanner){
            $scanner_script = $global:scanner_provisioning[$scanner_iterator]
            $scanner_type = $global:box_scanner_types[$scanner_iterator]
            Write-Host "Current scanner $objectA, the type of the machine is a $scanner_type and the script $scanner_script" -ForegroundColor Red -BackgroundColor Yellow
            $scanner_iterator++
            foreach ($objectB in $global:box_vulnerable){
                $vulnerable_script = $global:vulnerable_provisioning[$vulnerable_iterator]
                $vulnerable_iterator++
                Write-Host "$objectA and $objectB are excecuted" -ForegroundColor Red -BackgroundColor Yellow
                Bootstrap -current_scanner $objectA -scanner_script $scanner_script -scanner_type $scanner_type -current_vulnerable $objectB -vulnerable_script $vulnerable_script -counter $counter -local_dir $local_dir
                $counter = $counter + 1
            }
        }
    }
    else {
        Write-Host "An error occured, some configurations were false: Please restart" -ForegroundColor Red
        Base-Menu
    }

}

# Start up the Base-Menu

Base-Menu