#!/bin/bash

#Script to insert local MySQL data into general collector database

#gets local data from mysql bannedips
#sends to collector (192.168.224.139)

mysqldump -t -h localhost -u root -ppassword banlist bannedIPs | mysql -h 192.168.224.139 -u root -ppassword banlist