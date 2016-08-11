#!/bin/bash

####script that sets up static IP 
#### created by Matthew Feng
###note script assume you are moving from dhcp to static, if netmask, gw can't be detected, manual input is nessasary
###can simplify by just prompting for the info

#1. Backup resolve.conf and /etc/sysconfig/network-scripts/eth0
#2. Check for distro version
#ask for ip and detect if it is valid - done
#checks fo rmask and gw and dns - work on dns
#confirms info before a key is pressed to make changes
#restart services
#ping check
#if machine is not on the network, manually prompt for info and use at own risk

####need to implement chice to enter manually to do auto detect or manual, if automattic fails, then prompt for manual 

function distro_check {
    if [ -f /etc/redhat-release ]; then
	echo "Checking your Linux flavor....."
	sleep 1
        echo "You are running Redhat!"
	os=RedHat
    elif [ -f /etc/lsb-release ]; then
        echo "Checking your Linux flavor....."
	sleep 1
	echo " You are running Ubuntu!"
	os=Debian
    else
	echo "Sorry I don't know what distro you are running"
        exit 0
fi
}

function m_changes {
rh_path="/etc/sysconfig/network-scripts"
d_path="/etc/networking"   
    case $os in
        "RedHat")
            echo "You are definately running RedHat"
            set_dns
        #need to prompt to see which eth0 to modify
            if [ -f $rh_path/ifcfg-eth0 ]; then
                echo "Backing up your ifcfg-eth0 file"
#		cp $rh_path/ifcfg-eth0 $rh_path/ifcfg-eth0.bak
		sleep 1
                echo "Configuring your static IP....Please wait"
##add code that appends file
		sleep 1
            fi
        ;;
        "Debian")
            echo "You are definately running Debian"
            set_dns
            if [ -f $d_path/interfaces ]; then
                echo "Modifying your interfaces file..."
		sleep 1
#		cp $d_path/interfaces $d_path/interfaces.bak
		echo "Modifying your intefaces file...."
		sleep
            fi
        ;;
        *)
            echo "I have no idea what distro this is"
        ;;
    esac

}

function net_info {
    mmask=$(route -n | grep 'U[ \t]' | awk '{print $3}') 
    mgw=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
    
    #Need to sperate the output and store into two variables
    mdns1=$(nm-tool | grep DNS | awk '{print $2}')
    mdns2=$(nm-tool | grep DNS | awk '{print $2}')
    echo "Pulling your network info"
    sleep 2
    echo "Your network mask is $mmask"
    echo "Your gateway is $mgw"
    echo "Your first DNS server IP is $mdns1"
    echo "Your second DNS server IP is $mdns2"
    sleep 5
}

###following 3 functions will prompt for info and makes sure you are entering correct info
function valid_ip {
#just need to test if it pings, assumes you are on connected to the network
    read_ip
    echo "Checking to see if the IP is valid...."
    sleep 1
    if [[ $sip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "The IP looks good"
    else
        echo "Invalid IP, please try another IP"  
        read_ip
    fi
}


function read_net_info {  #need to keep asking for right info *while loop*
 
#    for make it into a for loop
    
    echo "Please enter your network info"
#   

#    if [[ $mmask =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#	echo "The IP $mmask is a valid"
#    else
#	read -s -p  "Invalid subnet mask, please re-enter" mmask
#    fi
#
#   if [[ $mgw =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#        echo "The IP $mmask is a valid"
#    else
#        read -s -p  "Invalid subnet mask, please re-enter" mgw
#
#    fi
#
#    if [[ $mdns1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#        echo "The IP $mmask is a valid"
#    else
#        echo "Invalid subnet mask, please re-enter"
#        echo "Please enter your network info"
#        read mmask
#    fi
#
#    if [[ $mdns2 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#        echo "The IP $mmask is a valid"
#    else
#        echo "Invalid subnet mask, please re-enter"
#        echo "Please enter your network info"
#        read mmask
#    fi
}

ip_check=^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$

function validation {
    echo "What is your static IP?"
    read sip
    try=3
    while [ $try !=0 ]; do
        sleep 1
        if [[$sip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	    echo "Your IP $sip looks good"
        else
            try--
            echo "IP is bad, please try again.  You have $try more tries"
#        else
#            if [try EQ 0]
# 	    echo "You are out of tries"
#            exit
#            fi
        fi
   done
}


function valid_ip {
#just need to test if it pings, assumes you are on connected to the network
    validation
#    while [[ $sip != ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
#	echo "Invalid IP, please try another IP" 
#    done
}

function ping_test {
echo "Testing your new IP"
sleep 1
ping -c 3 $sip > /dev/null 2>&1
RESULT=$?
if [ ! "$RESULT" = 0 ]; then
    echo "We failed to ping $sip"
    echo "Rolling back changes"
#   function that revert changes
else
    echo "Looks like your new IP works"
    echo "Cleaning up changes"
   #function or code that goes back to remove commented lines
fi
}

function set_dns {
### back up resolve.conf
    if [ -f /etc/resolv.conf ]; then
	echo "Backing up your /etc/resolv.conf file...."
	sleep 1
        cp /etc/resolv.conf /etc/resolve.conf.bak
        echo "Modifying /etc/resolv.conf with your information"
#comments out dns info       sed -e '/name/s/^/#/g' -i /etc/resolv.conf
#        echo "nameserver $dns1" >> resolv.conf
#	echo "nameserver $dns2" >> resolv.conf
    fi
}

####main program####
function main {
#checking for root
    WHOAMI=$(/usr/bin/whoami)
    if [ ! "$WHOAMI" = "root" ]; then
	 echo "This script must run as root! Try using sudo..."
         exit 1
    fi

#checks for network connectivity and will auto or manually set IP
    echo "Checking to see if you are connected to the VMware network..."
    ping -c 2 source.vmware.com  > /dev/null 2>&1
    RESULT=$?
    if [ ! "$RESULT" = 0 ]; then
        distro_check
	echo "You are not connected to the VMware network...."
        echo "You will need to enter your network info manually"
	valid_ip
        echo "Your IP $sip looks good"
        read_net_info   #ask for other network info
        set_dns
        m_changes
	echo "Restarting your network services..."
	sleep 1
	service network restart
	ping_test
    else
        echo "You are connected to the VMware network, continuing..."
        distro_check
	valid_ip        #makes sure the ip looks good
        echo "Your IP $sip looks good"
	net_info  #displays netmask, gateway and dns
	m_changes       #update the os network file
	ping_test       #confirms the IP works	
   
    fi
}

main

###write a function that cleans up after successful ping 
###goes back and deletes all commented lines 
###then deletes backed up files
