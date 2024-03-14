#!/bin/bash

# 
# Enable postrouting packet forward from openvpn to local lan
# Local output lan interface is lan_interface
# OpenVPN source virtual interface tun0 network configuration is ovpn_network
#

# Configurazioni
ovpn_network="10.8.0.0/24"
lan_interface="wlp1s0"
rule_comment="openvpn-to-lan-nat-route-rule"

# Funzione per abilitare il postrouting
enable_postrouting() {
    if ! iptables -t nat -C POSTROUTING -o "$lan_interface" -s "$ovpn_network" -j MASQUERADE -m comment --comment "$rule_comment" &>/dev/null; then
        iptables -t nat -I POSTROUTING -o "$lan_interface" -s "$ovpn_network" -j MASQUERADE -m comment --comment "$rule_comment"
        echo "Postrouting rule enabled."
    else
        echo "Postrouting rule already enabled."
    fi
}

# Funzione per disabilitare il postrouting
disable_postrouting() {
    if iptables -t nat -C POSTROUTING -o "$lan_interface" -s "$ovpn_network" -j MASQUERADE -m comment --comment "$rule_comment" &>/dev/null; then
        iptables -t nat -D POSTROUTING -o "$lan_interface" -s "$ovpn_network" -j MASQUERADE -m comment --comment "$rule_comment"
        echo "Postrouting rule disabled."
    else
        echo "Postrouting rule is already disabled."
    fi
}

# Controllo degli argomenti passati
if [[ -z $1 ]]; then
    echo "*** Devi fornire un argomento. Digita '--help' per mostrare le istruzioni per l'uso. ***" >&2
    exit 1
fi

# Esegui il comando specificato dagli argomenti
case $1 in
    "enable")
        disable_postrouting
        enable_postrouting
        ;;
    "disable")
        disable_postrouting
        ;;
    "--help")
        echo "Utilizza 'enable' per abilitare il postrouting forward o 'disable' per disabilitare il postrouting forward."
        ;;
    *)
        echo "Comando sconosciuto. Utilizza '--help' per mostrare le istruzioni per l'uso." >&2
        exit 1
        ;;
esac
