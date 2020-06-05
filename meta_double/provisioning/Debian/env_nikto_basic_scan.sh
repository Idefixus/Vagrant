# Install the nikto scanner

sudo apt-get update
sudo apt-get install nikto -y

# Run a nikto scan
mkdir nikto
nikto -host $env:IP_VULNERABLE -output nikto/nikto_scan_results.htm

cd nikto
cp -u nikto_scan_results.htm /vagrant/nikto_scan_results.htm
echo $?