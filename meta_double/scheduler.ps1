# Scheduler / Model & part Controller

#Todo create separate Controller
# Set the manuell variable to no
$env:manuell = 0

#Set-StrictMode -Version 1
$vms = Get-Content .\vms.json | Out-String | ConvertFrom-Json

# Todo get the vm config:
[String[]] $global:scanner_names = @()
[String[]] $global:scanner_types = @()
[String[]] $global:scanner_os = @()
[String[]] $global:vulnerable_names = @()
[String[]] $global:vulnerable_types = @()
[String[]] $global:vulnerable_os = @()

foreach ($vm in $vms) {
    if($vm.type -eq "scanner"){
        $global:scanner_names += $vm.name
        $global:scanner_types += $vm.type
        $global:scanner_os += $vm.os
    }
    elseif($vm.type -eq "vulnerable"){
        $global:vulnerable_names += $vm.name
        $global:vulnerable_types += $vm.type
        $global:vulnerable_os += $vm.os
    }
}
# Chosen scanners
[String[]] $global:box_scanner = @()
[String[]] $global:scanner_provisioning = @()
[String[]] $global:box_scanner_types = @()
# Chosen vulnerables
[String[]] $global:box_vulnerable = @()
[String[]] $global:box_scanner_os = @()
[String[]] $global:vulnerable_provisioning = @()
[String[]] $global:box_vulnerable_types = @()
# Fill the current working directory with the current path
[String] $global:working_dir = $PSScriptRoot

[String[]] $global:chosen_konfig = @()

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
    # TODO: UTF8 Error
    #$enc = [System.Text.Encoding]::UTF8
    #$var = "$global:working_dir\$local_dir\$new_directory"
    #$env:SCOPE_DIR = $enc.GetBytes($var)
    $pattern ='[\\]'
    $string = "$global:working_dir\$local_dir\$new_directory"
    $replace = $string -replace $pattern, '\\'
    #$replace = $string -replace $pattern, '/'
    $env:SCOPE_DIR_plugin = $replace
    $env:SCOPE_DIR = "$global:working_dir\$local_dir\$new_directory"

    Write-Host "New working direcory: "$env:SCOPE_DIR -ForegroundColor Red -BackgroundColor Yellow

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
	Get-Content $global:working_dir\env_vagrantfile.sh | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$env:SCOPE_DIR\Vagrantfile"

	# Expand Provisioning files:
	Get-Content "$global:working_dir\provisioning\$scanner_type\$scanner_script" | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$env:SCOPE_DIR\$env:SCANNER_PROVISIONING_FILE_NAME"

    # Expand Provisioning files:
    # TODO: Custom vulnerable script --> Change like scanner
	Get-Content "$global:working_dir\provisioning\vulnerable_scripts\$vulnerable_script" | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString($_) } > "$env:SCOPE_DIR\$env:VULNERABLE_PROVISIONING_FILE_NAME"

    #TODO: Add custom scanner script here.
    # Box add & vagrant up

    Set-Location $env:SCOPE_DIR
    vagrant box add $current_vulnerable --provider virtualbox
    vagrant box add $current_scanner --provider virtualbox

    # Virtualbox as dependency
    vagrant up

    # Do the scan by hand because of bug: Works now
    #vagrant ssh scanner -c "echo 'Doing scan by hand'"
    #vagrant ssh scanner -c "sudo bash openvas_scan_automation_start.sh $env:IP_VULNERABLE"
    #vagrant ssh scanner -c "ip address > /vagrant/ip_scanner.txt"

    # Destroy the machines for purity and limitation of ssh errors and ip collisions also for triggering the :before destroy scripts
    if($env:manuell -eq 0){
    Write-Host "All machines are being destroyed (some scripts can be triggered during this process so this could take a while before the machines are actually destroyed)" -ForegroundColor Red -BackgroundColor Yellow
    vagrant destroy -f
    # Create the output file for this pairing
    Create-Html
    }
# Create Result folders

# Start scan with right parameters and provisioning scripts

    $EndMs = (Get-Date).Minute
    Write-Host "This script took $($EndMs - $StartMs) minutes to run." -ForegroundColor Red -BackgroundColor Yellow

}

function Create-Html{
    # Create a html result output file
    New-Item .\result_overview.html -ItemType File
    $localpath = Get-Location
    $subfolder = Get-Childitem -Path sync -Name

    $head = "<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Result HTML</title>
    <style>
table {
  font-family: arial, sans-serif;
  border-collapse: collapse;
  width: 100%;
}

td, th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 8px;
}

tr:nth-child(even) {
  background-color: #ffffff;
}
.button {
  font: bold 11px Arial;
  text-decoration: none;
  background-color: #EEEEEE;
  color: #333333;
  padding: 2px 6px 2px 6px;
  border-top: 1px solid #CCCCCC;
  border-right: 1px solid #333333;
  border-bottom: 1px solid #333333;
  border-left: 1px solid #CCCCCC;
}
</style>
</head>
<body>
<h2>All results of the current scan</h2>

<table>
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>"
    Add-Content result_overview.html $head
    $description = ""
    foreach($element in $subfolder){
        Get-ChildItem -Path .\sync\ | Where {$_.extension -like ".nmon"}
        if ($element -like '*.nmon'){
            $description = 'This is a result file of the nmon performance measurement tool. It is unformatted. For a graphical overview look for an html file with the same name.'
        }
        elseif($element -like '*.nmon'){

        }
        elseif($element -like '*.pcap'){
            $description = "This is a result of the network traffic. You can view it with a tool like Wireshark."
        }
        elseif($element -like 'tripwire_log.txt'){
            $description = "This is a tripwire result. It shows the differences of the filesystem according to the baseline set while configuring the scan-process. <a class='button' href='..\..\twpol.txt'> tripwire config </a>"
        }
        elseif($element -like '*openvas*.html'){
            $description = "This is an OpenVAS scan result. Click to see the scan results and configuration details."
        }
        elseif($element -like '*nikto*.html'){
            $description = "This is the Nikto scan result. Click to see the scan results and configuration details."
        }
        elseif($element -like '*.nmap'){
            $description = "This is the nmap scan result. Click to see the scan results and configuration details."
        }
        elseif($element -like 'performance_result.html'){
            $description = "This is a graphical overview file for the nmon Performance Analysis. Click to see more details"
        }
        elseif($element -like '*.html'){
            $description = "This is the scan result. Click to see the scan results and configuration details."
        }
        Add-Content result_overview.html "<tr>
            <td>
                <a class='button' href='file:///$localpath/sync/$element'> $element</a>
            </td>
            <td>
                $description
            </td>
        </tr>"
    }
    $body = Add-Content result_overview.html "<tr>
        <td>
            <a class='button' href='file:///$localpath/Vagrantfile'> Vagrantfile</a>
        </td>
        <td>
            This is the local Vagrant configuration file. It can be used to repeat the scan
        </td>
    </tr>"
    $feet = "</table>
    <br>
    <div> Note: To manually repeat the scan you can either use the user-interface or navigate to the Vagrantfile in the folder of the scan you want to repeat. Open PowerShell at this location and type 'vagrant up'. The scan will automatically be repeated. </div>
    <br>
    
    </body>
</html>"
Add-Content result_overview.html $feet
}

function Start-Bootstrap{

    #Iterator for the offset of the chosen machines for configurations
    $scanner_iterator = 0
    $vulnerable_iterator = 0

    foreach ($objectA in $global:box_scanner){
        $scanner_script = $global:scanner_provisioning[$scanner_iterator]
        if ($global:box_scanner_os -isnot [array]){
        $scanner_type = $global:box_scanner_os
        }
        else{

        $scanner_type = $global:box_scanner_os[$scanner_iterator]
        }
        Write-Host "Current scanner $objectA, the type of the machine is a $scanner_type and the script $scanner_script" -ForegroundColor Red -BackgroundColor Yellow
        $scanner_iterator++
        foreach ($objectB in $global:box_vulnerable){
            $vulnerable_script = $global:vulnerable_provisioning[$vulnerable_iterator]
            $vulnerable_iterator++
            Write-Host "$objectA and $objectB are excecuted" -ForegroundColor Red -BackgroundColor Yellow
            Bootstrap -current_scanner $objectA -scanner_script $scanner_script -scanner_type $scanner_type -current_vulnerable $objectB -vulnerable_script $vulnerable_script -counter $counter -local_dir $local_dir
            $counter = $counter + 1
        }
        $vulnerable_iterator = 0
    }

}

   # ------------- Enable-Plugins / Global configurations ------------- #

#Tripwire Plug-In
function Tripwire{
    $env:monitoring = 0

    Write-Host "Do you want to monitor the differences on the vulnerable machine while scanning? The result will be saved in the sync folder of the scan" -ForegroundColor Red -BackgroundColor Yellow
    [String] $monitoring = Read-Host -Prompt "y or n"
    if ($monitoring -eq "y"){
        # TODO: Load the monitoring provisioning script.
        # When monitoring 1 == 1 set the env variable for the tripwire_init.sh script
        $env:monitoring = 1
        Write-Host "Monitoring: [yes]"
        $global:chosen_konfig += "Plug-In: Tripwire"
    }

}

#Wireshark Plug-In
function Wireshark{
    $env:wireshark = 0
    

    Write-Host "Do you want to monitor the traffic between the VMs the result will be saved in the sync folder of the scan?" -ForegroundColor Red -BackgroundColor Yellow
    [String] $wireshark = Read-Host -Prompt "y or n"
    if ($wireshark -eq "y"){
        # Load the wireshark plug-in.
            
        $env:wireshark = 1
        Write-Host "Wireshark: [yes]"
        $global:chosen_konfig += "Plug-In: Wireshark"
    }  
}

# Nmon Plug-In
function Nmon{
        # Todo for scanner too

    $env:performance = 0
    Write-Host "Do you want to monitor the performance of the vulnerable the result will be saved in the sync folder of the scan?" -ForegroundColor Red -BackgroundColor Yellow
    [String] $performance = Read-Host -Prompt "y or n"
    if ($performance -eq "y"){
        # Load the nmon plug-in.
            
        $env:performance = 1
        Write-Host "Performance: [yes]"
        $global:chosen_konfig += "Plug-In: Nmon"
    }
}
         
# TODO: maybe vb plugin. But this should be default tbh
# TODO: Track theses settings in a json for generating the final overview file.

function Clear-Config{
    # Clear the scan-configuration
    $global:chosen_konfig = @()
    $global:box_scanner = @()
    $global:box_vulnerable = @()
    $global:scanner_provisioning = @()
    $global:vulnerable_provisioning = @()
}

function Show-Config{
    $global:chosen_konfig += "Chosen scanners:"
    foreach ($scanner in $global:box_scanner){
        $global:chosen_konfig += $scanner
    }
    $global:chosen_konfig += "Chosen vulnerables:"
    foreach ($vulnerable in $global:box_vulnerable){
        $global:chosen_konfig += $scanner
    }

    Write-Host "You chose the following config for this scan:"
    foreach ($string in $global:chosen_konfig){
        Write-Host $string
    }
}
