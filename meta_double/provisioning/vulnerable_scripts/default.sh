echo "The custom provisioning script was chosen for this vulnerable"

#Install nano for test cases
sudo apt-get -y install nano 

wget https://launchpad.net/~ubuntu-security/+archive/ubuntu/ppa/+build/7531893/+files/openssl_1.0.1-4ubuntu5.31_amd64.deb
sudo dpkg -i openssl_1.0.1-4ubuntu5.31_amd64.deb