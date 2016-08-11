 #!/bin/bash

#### script that changes your home directory to local /home on hdd ####
#### created by Matthew Feng


#### Testing to see if the user is running as root ####
WHOAMI=$(/usr/bin/whoami)
if [ ! "$WHOAMI" = "root" ]; then
	 echo "This script must run as root! Try using sudo..."
         exit 1
fi

echo "What is your name?"
read name

#need to check if the uid is valid
echo "What is your user id?"
read id

#need to get value to save to variable
uid1=$(exec id $id | cut -d ' ' -f1 | sed 's/[^0-9]//g')
gid1=$(exec id $id | cut -d ' ' -f2 | sed 's/[^0-9]//g')


echo "Checking if the folder already exist"
sleep 1
if [ -d /home/$id  ]; then
	echo "Directory already exit..."
	sudo chown -R $id /home/$id 
else
	echo "Creating your home folder...."
	sleep 1
	sudo mkdir /home/$id
	sudo chown -R $id /home/$id
	echo "New home folder create.. at /home/$id"
fi
###need to check to see if there is already an entry
####if [ cat /etc/passwd | grep $id | sed 's/[$id]//g' ]

	 
echo "editing /etc/passwd.."
sleep 1
echo "$id:x:$uid1:$gid1:$name:/home/$id:/bin/bash" >> /etc/passwd
echo -e "Your home directory is now located on /home/$id.\n Please save your work and log out and back in"
sleep 1

