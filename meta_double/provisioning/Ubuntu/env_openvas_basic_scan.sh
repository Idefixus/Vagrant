echo "Doing a openvas basic scan"

# Timer needed because of startup time of demon
sleep 1m

sudo bash openvas_scan_automation_start.sh $env:IP_VULNERABLE
#sudo bash openvas_scan_automation_start.sh 192.168.178.24
echo "Scan finished"