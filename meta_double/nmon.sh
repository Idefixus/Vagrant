# Install ksh for nmonchart - Do it here to not disturb the results
sudo apt-get install nmon -y
sudo apt-get install ksh -y

# Track the usage for the next 5000 seconds.
nmon -F 'performance_result.nmon' -s5 -c 500