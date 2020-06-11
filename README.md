 --- This is my vagrant release candidate branch. ---
 
 This is a testbed for vulnerability scanners. You can test multiple vulnerability scanners and compare them with each other.
 In the testbed you first choose the scanners and then the vulnerable machines to test against. You also choose the scan scripts and and the scripts to run on the vulnerable.
 Before starting the scan you can choose a number of plug-ins supporting and enhancing the scan process. The scan will run automatically and provide all results in a subfolder. An overview result file combines all the results and can be found in each scanner-vulnerable subfolder.
 
 # Installation
 
 - To install clone the repository
 - Install VirtualBox
 - Install Vagrant
 - Install PowerShell (If you are working on Linux)
 
 # Run
 
 - Route to the folder meta_double
 - Open a PowerShell console and start with configuring the testbed through executing the interactive kontext.ps1 script. Further information about the configuration options can be found in my masters thesis
 - Once configuration is done, you can start the scan-configuration process. It is straight forward but further information can be found in my masters thesis.
 
 
 
# Linux Usage

- For linux you have to first install PowerShell from the Windows repository: 
(see: https://docs.microsoft.com/de-de/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7)
- You also have to add Vagrant to the path for the testbed to work.

# Known Bugs

- If you want to use the wireshark plugin in Linux you have to edit the env_vagrantfile.sh.
In line 48 and 49 (can change through time) you have to replace \\ with / . This is because of the way the linux file system works.
- If you do a nikto vulnerability scan on a server which has no webserver running to testbed fails
- A notification, that a machine has already been created exists when rerunning a scan with the same VM (see: https://github.com/Idefixus/Vagrant/issues/56)

# Impressions


