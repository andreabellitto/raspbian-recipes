#!/bin/bash

# Derived from a script by @arpitjindal97 originally made for Raspbian stretch
# Original source: https://github.com/arpitjindal97/raspbian-recipes
# 
# Bridge WiFi with Ethernet
# Internet source is wlan0
# wpa_supplicant will be running on wlan0
#
# This is Layer 3 proxy arp solution
#
# This script is made to work with Raspbian Buster
# but it can be used with most of the distributions
# by making few changes.
#
# Make sure you have already installed:
# 	avahi-daemon
# 	parprouted
#	dhcp-helper
#	wpasupplicant (optional)
#
# Just install these packages and don't touch
# any configuration file. This script will handle
# required options dynamically.
#
# wpa_supplicant is needed only for headless systems
# that does't have a GUI and network-manager that
# automatically manage the Wi-Fi interface connection
# to the Wi-Fi hotspot after the system boot.
# Configure /etc/wpa_supplicant/wpa_supplicant.conf
# prior to this script if needed.
#

eth="enp3s0"
wlan="wlp1s0"
subnet="24"

bridge_disable() {
    sudo systemctl start network-online.target &> /dev/null
    sudo iptables -F
    sudo iptables -t nat -F
    
    echo "Killing parprouted "
    sudo killall parprouted &> /dev/null
    echo "Stopping dhcp-helper service"
    sudo systemctl stop dhcp-helper
    echo "Killing dhcp-helper"
    sudo killall dhcp-helper &> /dev/null
    echo "Stopping avahi-daemon service"
    sudo systemctl stop avahi-daemon
    echo "Killing avahi-daemon"
    sudo killall avahi-daemon &> /dev/null

    echo "Flushing $eth IP addr"
    sudo ip addr flush dev $eth
}

bridge_enable() {
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    
    echo "Creating temp avahi conf file"
    cp /etc/avahi/avahi-daemon.conf /tmp/avahi-daemon.conf
    sed -i 's/^enable-reflector=no/enable-reflector=yes/' /tmp/avahi-daemon.conf
    sed -i 's/^#enable-reflector=no/enable-reflector=yes/' /tmp/avahi-daemon.conf
    
    option=$(cat /tmp/avahi-daemon.conf | grep enable-reflector=yes)
    if [ $option=="" ]; then
            echo -e '\n[reflector]\nenable-reflector=yes\n' >> /tmp/avahi-daemon.conf
    fi
    
    echo "Starting parprouted ..."
    sudo /usr/sbin/parprouted $eth $wlan &
    
    echo "Starting dhcp-helper ..."
    sudo /usr/sbin/dhcp-helper -r /var/run/dhcp-helper.pid -b $wlan &
    
    echo "Flushing $eth IP addr"
    sudo ip addr flush dev $eth
    
    echo "Assigning IP to $eth from $wlan"
    sudo /sbin/ip addr add $(/sbin/ip addr show $wlan | perl -wne 'm|^\s+inet (.*)/| && print $1')/$subnet dev $eth &
    
    sleep 2

    echo "Starting avahi-daemon ... "
    avahi-daemon -f /tmp/avahi-daemon.conf &
}

if [ -z $1 ]
then
  echo "*** You must provide an argument. Type --help to show usage instruction  ***"
  exit 1
elif [ -n $1 ]
then
# otherwise make first arg as command
  cmd=$1
fi

case $cmd in

  "enable")
    bridge_disable
    bridge_enable
    ;;

  "disable")
    bridge_disable
    ;;

  "--help")
    echo "Use enable argument to enable the bridge or disable argument to disable the bridge"
    ;;
  
  *)
    echo "unknown command"
    exit 1
    ;;

esac
