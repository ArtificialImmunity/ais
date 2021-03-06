#!/bin/bash

#Author Jordan Bruce

#This script takes in the argument as 'username@ip" it will then signal all agents
#that are registered with the collector to ban that ip

#Checks collector to see if there is a rule currently banning this ip from all traffic
#If a local rule has already been set, it is assumed that all agents have the same rule
#and thus do not add the same rule again
sudo iptables -C INPUT -s $1 -j DROP

if [ $(echo $?) == 1 ]; then

    #If there is no rule, add a local iptables rule to ban all traffic from ip
    sudo iptables -A INPUT -s $1 -j DROP; sudo iptables -A OUTPUT -d $1 -j DROP

    #Then if there was an argument given, set a rule on all agents in agent list to ban also
    if [ $# -eq 1 ]; then #if  number of args = 1, i.e. 1 ip address
        while read ip
        do
            ssh $ip "/usr/bin/sudo bash -c 'iptables -A INPUT -s $1 -j DROP; iptables -A OUTPUT -d $1 -j DROP'" &
        done </usr/local/src/ais/agents/allAgentIPs
    fi;
fi;
