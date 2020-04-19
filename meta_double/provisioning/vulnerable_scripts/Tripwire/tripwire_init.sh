# Initialize the tripwire software for detecting differences created during the scan process

# disable the frontend for automation
export DEBIAN_FRONTEND=noninteractive
# install tripwire without interactive menu
apt-get -qq -y install tripwire
# Create the new configuration with the right folders
twadmin -m P -Q "" /home/vagrant/twpol.txt
#init the baseline database
tripwire --init -P ""
# mkdir test_tripwire
# tripwire --check