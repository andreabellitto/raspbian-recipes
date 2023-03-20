#!/bin/bash

##
## 1. Create the following shell script check-inet.sh:
##
##	#!/bin/bash
##	
##	TMP_FILE=/tmp/inet_up
##
## 	#Edit this function if you want to do something besides reboot
##	no_inet_action() {
##	    shutdown -r +1 'No internet.'
##	}
##
##	if ping -c5 google.com; then
##    		echo 1 > $TMP_FILE
##	else
##    		[[ `cat $TMP_FILE` == 0 ]] && no_inet_action || echo 0 > $TMP_FILE
##	fi
##
## 2. Change the permissions so it is executable
##
##	$ chmod +x check-inet.sh
##
## 3. Edit /etc/crontab using sudo and add the following line (replace yourname with your actual username):
##
##	*/30 * * * * /home/yourname/check-inet.sh
##

THIS_SCRIPT_NAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
TMP_FILE=/tmp/inet_up
#LOG_FILE=/var/log/$THIS_SCRIPT_NAME.log
LOG_FILE=/var/log/check-inet.log

# Edit this function if you want to do something besides reboot
no_inet_action() {
    systemctl restart network-manager
    date >> $LOG_FILE
}

if ping -c5 192.168.1.1; then
    echo 1 > $TMP_FILE
else
    [[ `cat $TMP_FILE` == 0 ]] && no_inet_action || echo 0 > $TMP_FILE
fi
