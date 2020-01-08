# Script for starting vagrant 
Write-Host "Start vagrant process"

$vagrantfile_path = Read-Host -Prompt 'Enter Vagrantfile path leave empty if this directory should be taken: '

if ($vagrantfile_path -eq ""){
    echo "true"
    $env:IP_SCANNER = "172.16.16.2"
    $ip_scanner = $env:IP_SCANNER

    echo ("The Scanner IT-Address  is: " + $ip_scanner)
    $env:IP_VULNERABLE = "172.16.16.3"
    $ip_vulnerable = $env:IP_VULNERABLE

    vagrant up
    echo "Vagrant is now upping"
	Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
    
} 
else {
    echo "false"
	Write-Host "Press any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}


