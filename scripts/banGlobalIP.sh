#!/bin/bash

#for ip in allAgents
#block all incomming and outgoing traffic from arg $1 (ip addr)
if [ $# -eq 1 ]; then #if  number of args = 1, i.e. 1 ip address
    while read ip
    do
            ssh ubuntu@ip 'iptables -A INPUT -s $1 -j DROP'
            ssh ubuntu@ip 'iptables -A OUTPUT -d $1 -j DROP'
    done </usr/local/src/ais/agents/allAgentIPs
fi;
