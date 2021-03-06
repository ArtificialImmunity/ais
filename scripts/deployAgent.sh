#!/bin/bash

#Author Jordan Bruce

#Script that automatically deploys an agent over ssh
#Keys are generated automatically
#files are copied over ssh
#Agent install script is ran over ssh
#Out put is logged to collector

#generate keys, get collector user to enter root pass of agent node

sudo -u root -H bash -c "if [ ! -f /root/.ssh/id_rsa ]; then ssh-keygen -t rsa; fi"
sudo -u root -H bash -c "ssh-copy-id $1"


#Set up file structure and copy agent files over
AISFILEPATH="/usr/local/src/ais/"
AISDEPLOYPATH="/usr/local/src/ais/deploy/ais/"

#make deploy folders
mkdir /usr/local/src/ais/deploy $AISDEPLOYPATH $AISDEPLOYPATH/agents $AISDEPLOYPATH/scripts $AISDEPLOYPATH/tablesmysql

#copy agent files to deploy folder
cp $AISFILEPATH/agents/{__init__.py,agentlib.py,netagent.py,sysagent.py} $AISDEPLOYPATH/agents/

#copy scripts to deploy folder
cp $AISFILEPATH/scripts/{collectAndFlush.sh,startbarnyard.sh} $AISDEPLOYPATH/scripts

#copy tables structs to deploy folder
cp $AISFILEPATH/tablesmysql/{create_mysql_banlist_agent,create_mysql_syslog} $AISDEPLOYPATH/tablesmysql

#copy over scripts
scp -r $AISDEPLOYPATH $1:~/ > /dev/null
#remove local deplot file after it's been copied
rm -r $AISFILEPATH/deploy
#mv the ais agent file to /usr/local/src
ssh -t $1 "sudo mv $HOME/ais /usr/local/src/"
#if log file doesn't create it, make it
if [ ! -d /var/log/deployagents ]; then mkdir /var/log/deployagents; fi
#run install script over ssh and send output to log file which install runs in back ground
ssh $1 "/usr/bin/sudo bash -s" < $AISFILEPATH/scripts/agentInstall.sh > /var/log/deployagents/$1 2>&1 &
#print out infor to user about deployment status
printf "\nAgent is being deployed... \n...this may take a few minutes. \nPlease check /var/log/deployagents/$1 for deployment log\n"
#add deployed ip to allAgentIPs list
echo "$1" >> $AISFILEPATH/agents/allAgentIPs
