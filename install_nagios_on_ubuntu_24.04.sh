#!/bin/bash

###############################################################################################################
# NOTE: This script will download, compile and install Nagios server and the official Nagios plugins. It will #
# only work on an Ubuntu 24.04 system. For best results, run this on a freshly installed system.              #
###############################################################################################################

###  WARNING: Do NOT run this script on a server that is running things you care about. Things might break! ###

# Function to check Ubuntu version
check_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "24.04" ]; then
            echo "This is Ubuntu 24.04. Great, we can continue."
            return 0
        else
            echo "You are not on Ubuntu 24.04 which is a requirement for this script." >&2
            exit 1
        fi
    else
        echo "Error: /etc/os-release file not found. Cannot determine OS/distro version." >&2
        exit 1
    fi
}

check_ubuntu_version


echo;echo "Installing Nagios server.";echo

sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt-get install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php libgd-dev

sudo apt-get install -y openssl libssl-dev

mkdir ~/nagios_src

cd ~/nagios_src || exit

wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-4.5.3/nagios-4.5.3.tar.gz
tar xzf nagios-4.5.3.tar.gz

cd ~/nagios_src/nagios-4.5.3 || exit
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make all

sudo make install-groups-users
sudo usermod -a -G nagios www-data
sudo make install
sudo make install-daemoninit
sudo make install-commandmode
sudo make install-config

sudo make install-webconf
sudo a2enmod rewrite
sudo a2enmod cgi

sudo ufw disable

sudo systemctl restart apache2.service
sudo systemctl start nagios.service


### INSTALL PLUGINS

sudo apt-get install -y autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

mkdir ~/nagios_plugins_src
cd ~/nagios_plugins_src || exit
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-2.4.10/nagios-plugins-2.4.10.tar.gz
tar xzf nagios-plugins-2.4.10.tar.gz

cd nagios-plugins-2.4.10 || exit
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install



echo;echo
echo "INSTALLATION DONE. Please run:

sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

to set a password for the nagiosadmin user";echo
