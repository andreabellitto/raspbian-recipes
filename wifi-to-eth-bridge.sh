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

# Definizione delle interfacce
eth="enp3s0"
wlan="wlp1s0"
subnet="24"

# Funzione per abilitare il bridge
bridge_enable() {
    # Abilita il forwarding IP
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    
    # Modifica temporanea del file di configurazione di avahi
    sudo sed -i 's/^enable-reflector=no/enable-reflector=yes/' /etc/avahi/avahi-daemon.conf 2>/dev/null || \
    echo -e '\n[reflector]\nenable-reflector=yes\n' | sudo tee -a /etc/avahi/avahi-daemon.conf >/dev/null
    
    # Avvia parprouted e dhcp-helper
    sudo /usr/sbin/parprouted $eth $wlan &
    sudo /usr/sbin/dhcp-helper -r /var/run/dhcp-helper.pid -b $wlan &
    
    # Imposta l'indirizzo IP per l'interfaccia Ethernet
    sudo ip addr flush dev $eth
    sudo /sbin/ip addr add $(/sbin/ip addr show $wlan | awk '/inet / {print $2}')/$subnet dev $eth &
    
    # Avvia avahi-daemon
    sudo systemctl start avahi-daemon
}

# Funzione per disabilitare il bridge
bridge_disable() {
    # Ferma tutti i servizi e processi necessari
    sudo systemctl stop avahi-daemon
    sudo killall avahi-daemon
    sudo systemctl stop dhcp-helper
    sudo killall dhcp-helper
    sudo systemctl stop network-online.target
    sudo iptables -F
    sudo iptables -t nat -F
    sudo killall parprouted
    sudo ip addr flush dev $eth
}

# Controllo degli argomenti passati
if [[ -z $1 ]]; then
    echo "*** Deve essere fornito un argomento. Utilizzare '--help' per mostrare le istruzioni d'uso. ***" >&2
    exit 1
fi

# Esegue il comando specificato dagli argomenti
case $1 in
    "enable")
        bridge_disable
        bridge_enable
        ;;
    "disable")
        bridge_disable
        ;;
    "--help")
        echo "Utilizzare 'enable' per abilitare il bridge o 'disable' per disabilitare il bridge."
        ;;
    *)
        echo "Comando sconosciuto. Utilizzare '--help' per mostrare le istruzioni d'uso." >&2
        exit 1
        ;;
esac
