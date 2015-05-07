#!/bin/bash

#Author Jordan Bruce

#Script to resets all databases on local agent

#NO LONGER IN USE
#gets local data from mysql bannedips
#sends to collector (192.168.224.139)
#mysqldump -t -h localhost -u banlist -ppassword banlist bannedIPs | mysql -h 192.168.224.139 -u banlist -ppassword banlist


#find the PID of the running barnyard instance
ps axu | grep barnyard | grep -v grep | awk '{print $2}' >> pids
#Kill barnyard so we can reset the database
while read pid
do
        kill $pid
done <pids
rm pids


#stop snort so we can reset database and logs without errors
#This will result in lost packets for brief moment, but
#The overall goal here is the general trend so a few
#lost packets shouldn't make much of a difference
service snort stop

#Drop all snort related tables and recreate databases/tables
if [ -d /var/lib/mysql/snort ]; then
    echo "DROP DATABASE snort;" >> mysqlCommands
    echo "DROP DATABASE archive;" >> mysqlCommands
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Create snort tables again
if [ ! -d /var/lib/mysql/snort ]; then

    for mysqlCommand in "CREATE DATABASE snort;" "CREATE DATABASE archive;" "GRANT USAGE ON snort.* to snort@localhost;" "GRANT USAGE ON archive.* to snort@localhost;" "set password for snort@localhost=PASSWORD('password');" "GRANT ALL PRIVILEGES ON snort.* to snort@localhost;" "GRANT ALL PRIVILEGES ON archive.* to snort@localhost;" "FLUSH PRIVILEGES;" "USE snort;" "SOURCE /usr/src/create_mysql;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
    rm /var/log/snort/*
#   rm /var/log/barnyard2/*

fi;

#Drop all syslog related databases and recreate them
if [ -d /var/lib/mysql/syslog ]; then
    echo "DROP DATABASE syslog;" >> mysqlCommands
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Create syslog tables again
if [ ! -d /var/lib/mysql/syslog ]; then

    for mysqlCommand in "CREATE DATABASE syslog;" "GRANT USAGE ON syslog.* to syslog@localhost;" "GRANT ALL PRIVILEGES ON syslog.* to syslog@localhost;" "FLUSH PRIVILEGES;" "USE syslog;" "SOURCE /usr/local/src/ais/tablesmysql/create_mysql_syslog;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Drop all banlist related databases and recreate them
if [ -d /var/lib/mysql/banlist ]; then
    echo "DROP DATABASE banlist;" >> mysqlCommands
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Creates banlist tables again
if [ ! -d /var/lib/mysql/banlist ]; then

    for mysqlCommand in "CREATE DATABASE banlist;" "GRANT USAGE ON banlist.* to banlist@localhost;" "GRANT ALL PRIVILEGES ON banlist.* to banlist@localhost;" "FLUSH PRIVILEGES;" "USE banlist;" "SOURCE /usr/local/src/ais/tablesmysql/create_mysql_banlist_agent;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Start snort up again
service snort start
#Get barnyard running again
. /usr/local/src/ais/scripts/startbarnyard.sh
