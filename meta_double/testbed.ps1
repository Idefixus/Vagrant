# Testbed (UI) / View & Controller

# Handling Parameters
#TODO Create separate viw and only call here
# Parameter for handling the mode (up or provision, ...)
param (
[String]$mode 
)

#Importing the Scheduler Module
. .\scheduler.ps1


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
    Write-Host "4: Get the scan-results."
    Write-Host "5: Start a Scanner-Vulnerable-Pair in manual mode."
	Write-Host "6: Redo a scan"
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
            # Start the scan. Show the config and prompt for starting
            Scan-Start
        }
        '4' {
            Results-Menu
        }
		'5' {

            
            if (($global:box_scanner.Count -eq 1) -and ($global:box_vulnerable.Count -eq 1)){

                    # Start manual mode with the selected VMs but you have to issue the scans and provisioning yourself. The scripts can be found in the respective folders. You can send them through SSH or through putting them in the synchronized folders.
                    $env:manuell = 1
                    
                    # Start the scan. Show the config and prompt for starting
                    Scan-Start
                    Finished
                    }
                
            else {
            Write-Host "Not enough or too many scanners or vulnerables chosen. In this mode you have to select One Scanner and One Vulnerable"
            Base-Menu
            }

        }
        '6'{
        $recent_scans = Get-Childitem -Path Scans_* -Name
                foreach($sc in $recent_scans){
                    $index = [array]::IndexOf($recent_scans,$sc)
                    #TODO: Do nicer... I hate arrays
                    $index += 1
                    Write-Host $index":"$sc
                }


                $input = Read-Host -Prompt "Choose a Scan to repeat."
                
                foreach($sc in $recent_scans){
                    $index = [array]::IndexOf($recent_scans,$sc)
                    $comp = $input - 1
                    if($comp -eq $index){
                           # TODO: Inline doesnt work. Fix it
                           Write-Host "Scan restarted: $sc"
                           cd $sc
                           $subscans = Get-Childitem -Name
                           foreach($sub in $subscans){
                                # TODO: Foreach element in subfolder do vagrant up.
                                cd $sub
                                vagrant up
                                # TODO Vagrant destroy
                                #Write-Host "All machines are being destroyed"
                                #vagrant destroy -f
                            }
                    }
                }

        }
       }
    
}

# Recursive menu for destroying all machines when you press yes

function Finished
{
    $finished = Read-Host -Prompt "You are in manuel mode: To continue and destroy the machines please enter 'yes' here."
    if ($finished -eq "yes")
    {
        Write-Host "All machines are being destroyed" -ForegroundColor Red -BackgroundColor Yellow
        vagrant destroy -f
        Exit 0
    }
    else 
    {
        Finished
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
            $machine_type = $($global:scanner_os[$scanner-1])

            #Set the global variables for the current scan
            $global:box_scanner += $($global:scanner_names[$scanner-1])
            $global:box_scanner_os += $machine_type


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


function Scan-Start
{
    [int] $counter = 1
    [String] $scanner_type = ""


    # ----------- #
    
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
       
        # Enable Plug-Ins #

        Tripwire
        Wireshark
        Nmon

        # Show the config of the scan and prompt for start
        Show-Config

        $choice = Read-Host -Prompt "Do you want to continue with the scan or restart the configuration process? (y or n)"
    
        if ($choice -ne "y"){
            Clear-Config
            Base-Menu
        }
        else{
 
        # Continue

            # Create a subfolder for the scans for persistence
            $time = Get-Date -DisplayHint Date -Format FileDateTime
            New-Item -ItemType Directory -name "Scans_$time" -Path "$global:working_dir"
            $local_dir = "Scans_$time"

            # Loop over all the combinations and start the processes one after another!
            Write-Host "Scan(s) started" -ForegroundColor Red -BackgroundColor Yellow
        
            # Start the scan process
            Start-Bootstrap
        }
    }
    else {
        Write-Host "An error occured, some configurations were false: Please restart" -ForegroundColor Red
        Base-Menu
    }
}

# Start up the Base-Menu

Base-Menu