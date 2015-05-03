#!/bin/bash

#1 deploy agent from collector
#2 agentInstall script is ran over ssh
#3 agents collector ip is updated
#4 ssh keys are generated for collector to access agent
#5 update allAgentIP file on collector

#Collector should now have list of all agents
#and have passwordless authentication to set iptables rules for global ban