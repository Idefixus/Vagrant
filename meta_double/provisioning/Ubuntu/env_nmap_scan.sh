# Scan process

echo "Starting a nmap scan"
apt-get install nmap --assume-yes
mkdir nmap
nmap -sC -sV -oA nmap/nmap_scan_results $env:IP_VULNERABLE
cd nmap
cp -u nmap_scan_results.nmap /vagrant/nmap_scan_results.nmap