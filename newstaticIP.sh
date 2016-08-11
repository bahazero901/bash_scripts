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

# need to update
#1. force dhcp mode to get network info
#2. 

function distro_check {
	echo "Checking your Linux flavor....."
    if [ -f /etc/redhat-release ]; then
		sleep 1
        echo "Looks like you are running a RedHat distro"
		os=RedHat
    elif [ -f /etc/lsb-release ]; then
		sleep 1
		echo "Looks like you are running a Debian distro!"
		os=Debian
    else
	echo "Sorry I don't know what distro you are running"
        exit 0
	fi
}


rh_path="/etc/sysconfig/network-scripts"
d_path="/etc/network"   

function make_changes {
    case $os in
        "RedHat")
            echo "You are definately running RedHat"
            #set_dns
            if [ -f $rh_path/ifcfg-eth0 ]; then
                echo "Configuring your static IP....Please wait"
				echo "IPADDR=$sip" >> $rh_path/ifcfg-eth0
				echo "IPADDR=$mmask" >> $rh_path/ifcfg-eth0
				echo "IPADDR=$mgw" >> $rh_path/ifcfg-eth0
				sleep 1
            fi
        ;;
        "Debian")
            echo "You are definately running Debian"
            #set_dns
            if [ -f $d_path/interfaces ]; then
				echo "auto eth0" >> $d_path/interfaces
				echo "iface eth0 inet static" >> $d_path/interfaces
				echo "address $sip" >> $d_path/interfaces
				echo "netmask $nmask" >> $d_path/interfaces
				echo "gateway $mgw" >> $d_path/interfaces
				sleep 1
            fi
        ;;
        *)
            echo "I have no idea what distro this is. Exiting..."
            exit 1
        ;;
    esac
}

#maybe not needed in own function integrate with distrocheck
function backup {
	if [ -f $rh_path/ifcfg-eth0 ]; then
        echo "Backing up your ifcfg-eth0 file"
		cp $rh_path/ifcfg-eth0 $rh_path/ifcfg-eth0.bak
		sleep 1
    fi

    if [ -f $d_path/interfaces ]; then
        echo "Backing up your interfaces file..."
		sleep 1
		cp $d_path/interfaces $d_path/interfaces.bak
		sleep 1
	fi
}

#integrate with distro check
function set_dhcp {
   case $os in
        "RedHat")
            if [ -f $rh_path/ifcfg-eth0 ]; then
            	#comment out all static
            	sed -e '/^BOOT/s/^/#/g' -i $rh_path/ifcfg-eth0 
            	echo "BOOTPROTO=dhcp" >> $rh_path/ifcfg-eth0 
				sleep 1
            fi
        ;;
        "Debian")
            if [ -f $d_path/interfaces ]; then
            	#create a new file
				echo "auto eth0" >> $d_path/interfaces
				echo "iface eth0 dhcp" >> $d_path/interfaces
				sleep 1
            fi
        ;;
        *)
            echo "I have no idea what distro this is. Exiting..."
            exit 1
        ;;
    esac
}
	

#backups /etc/resolv.conf, then comments old dns info and then appends new info
function set_dns {
		sed -e '/name/s/^/#/g' -i /etc/resolv.conf   #comments out original nameserver
        echo "nameserver $mdns1" >> resolv.conf
		echo "nameserver $mdns2" >> resolv.conf
}

#integrate with backup?
function backup_dns {
	if [ -f /etc/resolv.conf ]; then
		echo "Backing up your /etc/resolv.conf file...."
		sleep 1
    	cp /etc/resolv.conf /etc/resolve.conf.bak
    fi
}
    

#if connected to network, this function will pull the subnet mask, gateway and dns info
function net_info {
    mmask=$(route -n | grep 'U[ \t]' | awk '{print $3}') 
    mgw=$(route -n | grep 'UG[ \t]' | awk '{print $2}')
    mdns1=$(nm-tool | grep DNS | awk '{print $2}' | head n1)
    mdns2=$(nm-tool | grep DNS | awk '{print $2}' | tail n1) 
    echo "Pulling your network info"
    sleep 1
    echo "Your network mask is $mmask"
    echo "Your gateway is $mgw"
    echo "Your first DNS server IP is $mdns1"
    echo "Your second DNS server IP is $mdns2"
    sleep 1
}


#For manual check of IP input and checks for validate IP via 
function validate_IP {
    echo "What is your static IP?"
    read sip

        if [[ ! $sip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "IP is bad, please try again....."
        else
	    	echo "Your IP $sip looks good"
	    	break
        fi
}


function ping_test {
    echo "Restarting your network services..."
	sleep 1
	service network restart
	sleep 1
	echo "Testing your new IP"
	ping -c 3 $sip > /dev/null 2>&1
	RESULT=$?
	if [ ! "$RESULT" = 0 ]; then
    	echo "We failed to ping $sip"
    	echo "Rolling back changes.  Please run the script again and make sure you are inputting the correct IPs"
		chg_revert
		sleep 1
		echo "Exiting...."
	else
    	echo "Looks like your new IP works"
    	echo "Cleaning up changes"
   		clean_up
   		sleep 1
   		echo "Done!"
	fi
}

#clean up with for loop
function chg_revert {   
	if [ -f /etc/resolve.conf.bak ]; then
		rm /etc/resolve.conf
		mv /etc/resolv.conf.bak /etc/resolv.conf
	fi
	if [ -f $rh_path/ifcfg-eth0.bak ]; then
		rm - rh_path/ifcfg-eth0
		mv $rh_path/ifcfg-eth0.bak $rh_path/ifcfg-eth0
	fi
	if [ -f $d_path/interfaces.bak ]; then
		rm $d_path/interfaces 
		mv $d_path/interfaces.bak $d_path/interfaces
	fi
}

#clean up using for loop
function clean_up { 
	if [ -f $rh_path/ifg-eth0 ]; then
		sed '/#BO/d' -i $rh_path/ifcg-eth0
		sed '/#IP/d' -i $rh_path/ifcg-eth0
		sed '/#NET/d' -i $rh_path/ifcg-eth0
		sed '/#GAT/d' -i $rh_path/ifcg-eth0
		sed '/#na/d' -i /etc/resolv.conf 
	fi
	
	if [ -f $d_path/interfaces ]; then
		sed '/#iface/d' -i $d_path/interfaces
		sed '/#add/d' -i $d_path/interfaces
		sed '/#net/d' -i $d_path/interfaces
		sed '/#gate/d' -i $d_path/interfaces
		sed '/#na/d' -i /etc/resolv.conf 		
	fi
}

function main {
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
		echo "You are not connected to the VMware network...."
        echo "Make sure you are connected before running the script"
		exit
    else
        echo "You are connected to the VMware network, continuing..."
        distro_check	#checks distro of linux
        backup
        backup_dns
        set_dhcp
		validate_IP        #makes sure the ip looks good    
		net_info  #pulls info  displays netmask, gateway and dns
		make_changes       #update the os network files
		ping_test       #confirms the IP works	
    fi
}

main
