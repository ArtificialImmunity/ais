#!/bin/bash

#for ip in allAgents
#block all incomming and outgoing traffic from arg $1 (ip addr)

#Checks collector to see if there is a rule currently banning this ip from all traffic
#If a local rule has already been set, it is assumed that all agents have the same rule
#and thus do not add the same rule again
if [[ -n $(if [[ ! -n $(sudo iptables -L | grep "$1 " | grep all) ]]; then echo "1"; fi) ]]; then

    #If there is no rule, add a local iptables rule to ban all traffic from ip
    iptables -A INPUT -s $1 -j DROP; iptables -A OUTPUT -d $1 -j DROP

    #Then if there was an argument given, set a rule on all agents in agent list to ban also
    if [ $# -eq 1 ]; then #if  number of args = 1, i.e. 1 ip address
        while read ip
        do
            ssh ubuntu@$ip "/usr/bin/sudo bash -c 'iptables -A INPUT -s $1 -j DROP; iptables -A OUTPUT -d $1 -j DROP'" &
        done </usr/local/src/ais/agents/allAgentIPs
    fi;
fi;

#'iptables -A INPUT -s $1 -j DROP; iptables -A OUTPUT -d $1 -j DROP'"
