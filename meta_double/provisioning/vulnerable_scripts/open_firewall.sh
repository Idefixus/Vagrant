# Open Firewall for ping
echo "Firewall is being opened for ping to find the machine"
#sudo iptables -P INPUT ACCEPT
sudo iptables -I INPUT -j ACCEPT