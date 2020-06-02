# UI Greetings please configure the testbed before using it. Here you can add and remove VMs and skripts. This is also possible directly through putting the scripts at the respective folders.

function Menu{

Write-Host "Greetings, please configure the testbed before using it. Here you can add and remove VMs and skripts. This is also possible directly through putting the scripts at the respective folders."
Write-Host " "
# 3 options to choose
Write-Host "Please choose one option by pressing the key and enter:"
Write-Host "1: Add a VM to the system."
Write-Host "2: See all VMs or remove a VM from the environment"
Write-Host "3: View or add scripts. You can add different scripts"
Write-Host "4: End Script"


$user = Read-Host
    switch ($user){
        '1' {
            Add-VM-Menu
        }
        '2' {
            
            Remove-VM-Menu
        }
        '3' {
            
            Add-Scripts-Menu
        }
        '4' {
            Write-Host "You can now procede to start the main script"
            Exit 0
        }
    }

# List all vms in the system and choose one to delete

# List all scripts Give link to script to add to the system. 3 Options scanner, vulnerable, scan-script, plugin script

}

#Add a VM to the system
function Add-VM-Menu{
Write-Host "You entered the Add VM menu"
$name = Read-Host -Prompt "Bitte geben Sie den Namen der neuen VM an!"
$type = Read-Host -Prompt "Bitte geben Sie den VM-Typen der neuen VM an (z.B. scanner oder vulnerable)!"
$os = Read-Host -Prompt "Bitte geben Sie den OS-Typen an der neuen VM an (z.B. Ubuntu)!"

$json = Get-Content vms.json | Out-String | ConvertFrom-Json

# Add VM to vms.json

# Create Custom Object
$vm = New-Object PSCustomObject
$vm | Add-Member -type NoteProperty -name name -Value $name
$vm | Add-Member -type NoteProperty -name type -Value $type
$vm | Add-Member -type NoteProperty -name os -Value $os
# Add object to json String
$json += $vm
# Write to file
$json | ConvertTo-Json | Set-Content vms.json
Menu
}

# Function to remove a VM 
function Remove-VM-Menu{

$json = Get-Content vms.json | Out-String | ConvertFrom-Json

Write-Host $json
# TODO beautify the output

# List all VMs
foreach($vm in $json){
    $index = [array]::IndexOf($json,$vm)
   # $index -= 1
    Write-Host $index":" $vm.name $vm.type $vm.os
    
}
$length = $json.Length
Write-Host $length": Press to return to the menu: Return to the menu"

# Add VM
$input = Read-Host -Prompt "Choose a VM to remove (choose number and enter)"

    switch ($input){
        $length {
            Write-Host "Return to menu"
            
        }
        $input {
                    # Remove the input VM.
                    # Create new array without the respective VM       
                    $indexofremove = $json[$input]
                    $newVms = @()
                    foreach ($vm in $json)
                    {
                        $index = [array]::IndexOf($json,$vm)
                        if ($index -ne $input)
                        {
                            $newVms += $vm
                        }
                    }
                    # Write to file
                    $newVms | ConvertTo-Json | Set-Content vms.json
                    
                }
            }

Menu
}

function Add-Scripts-Menu{
Write-Host "Choose a script you want to add. Then enter a link to your script which you want to add to the system."

Write-Host "1: Scanner Script"
Write-Host "2: Vulnerable Script"
Write-Host "3: Szenario Scan Script"
Write-Host "4: Return"


$chosen = Read-Host
switch ($chosen){
    1 {
        Write-Host "Provide a link to the file."
        $link = Read-Host
        Copy-Item $link -Destination ".\provisioning\scanner_scripts"
        Add-Scripts-Menu
    }
    2 {
        Write-Host "Provide a link to the file."
        $link = Read-Host
        Copy-Item $link -Destination ".\provisioning\vulnerable_scripts"
        Add-Scripts-Menu
    }
    3 {
        Write-Host "What os type script do you want to add (z.B. Debian, Ubuntu)"
        $ostype = Read-Host
        $link = Read-Host -Prompt "Insert a link to the script"
        if ($ostype -eq "Debian"){
        Copy-Item $link -Destination ".\provisioning\Debian"
        Add-Scripts-Menu
        }
        elseif ($ostype -eq "Ubuntu") {
        Copy-Item $link -Destination ".\provisioning\Ubuntu"
        Add-Scripts-Menu
        }
        else {
            Write-Host "OS type not supported"
            Menu
        }
    }
    4 {
        Menu
    }
   }
}
Menu