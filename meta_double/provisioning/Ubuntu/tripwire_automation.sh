# https://medium.com/@Alibaba_Cloud/how-to-install-and-configure-tripwire-ids-on-ubuntu-16-04-d7941c6b4db9

apt-get install tripwire -y
tripwire --init
tripwire --check

tripwire --check
# Read out output or save output to file which is synced.

