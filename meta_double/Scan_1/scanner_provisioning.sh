echo I am provisioning the scanner from an external script...
loadkeys de
cd .
mkdir provisioning
cd provisioning
touch worked.txt

# Scan process

echo Starting a nmap scan
apt-get install nmap --assume-yes
mkdir nmap
nmap -sC -sV -oA nmap/nmap_scan_results 172.16.16.3
cd nmap
cp -u nmap_scan_results.nmap /vagrant/nmap_scan_results.nmap
