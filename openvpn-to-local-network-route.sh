#!/bin/bash

# 
# Enable postrouting packet forward from openvpn to local lan
# Local output lan interface is lan_interface
# OpenVPN source virtual interface tun0 network configuration is ovpn_network
#

ovpn_network="10.8.0.0/24"
lan_interface="wlp1s0"

nat_cmd="iptables -t nat"
roule="POSTROUTING -o $lan_interface -s $ovpn_network -j MASQUERADE"
roule_check_cmd=$(echo "$(iptables -t nat -L --line-numbers)" | egrep "^[0-9]" | wc -l)

postrouting_disable() {
    result=$roule_check_cmd
    if [ $result -ne 0 ]; then
        echo "Deleting the roule"
	$nat_cmd -D $roule
	wait $!
	sync
	result=$roule_check_cmd
	if [ $result -eq 0 ]; then
            echo "Roule deleted"
        else
            echo "Fail to delete the roule"
        fi
    else
        echo "The roule was not found"
    fi
}

postrouting_enable() {
    $nat_cmd -I $roule
    wait $!
    sync
    result=$roule_check_cmd
    if [ $result -eq 0 ]; then
        echo "Roule add success"
    else
        echo "Route add error: $result"
    fi
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
    postrouting_disable
    postrouting_enable
    ;;

  "disable")
    postrouting_disable
    ;;

  "--help")
    echo "Use enable argument to enable the postrouting forward or disable argument to disable the postrouting forward"
    ;;
  
  *)
    echo "unknown command"
    exit 1
    ;;

esac
