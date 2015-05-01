#!/bin/bash

#Author Jordan Bruce

apt-get update -y; apt-get upgrade -y;

#mysql install

cd; apt-get install mysql-server -y

#Snort MySQL set up

if [ ! -d /var/lib/mysql/snort ]; then
	for mysqlCommand in "CREATE DATABASE snort;" "CREATE DATABASE archive;" "GRANT USAGE ON snort.* to snort@localhost;" "GRANT USAGE ON archive.* to snort@localhost;" "set password for snort@localhost=PASSWORD('password');" "GRANT ALL PRIVILEGES ON snort.* to snort@localhost;" "GRANT ALL PRIVILEGES ON archive.* to snort@localhost;" "FLUSH PRIVILEGES;" "USE snort;" "SOURCE /usr/src/create_mysql;"
	do
		    echo $mysqlCommand >> mysqlCommands
	done
	mysql -u root -p --password='password'<mysqlCommands
	rm mysqlCommands
fi;

#SysLog MySQL set up

if [ ! -d /var/lib/mysql/syslog ]; then
    cd ais/
    for mysqlCommand in "CREATE DATABASE syslog;" "CREATE USER 'syslog'@'localhost' IDENTIFIED BY 'password';" "GRANT USAGE ON syslog.* to syslog@localhost;" "GRANT ALL PRIVILEGES ON syslog.* to syslog@localhost;" "FLUSH PRIVILEGES;" "USE syslog;" "SOURCE /home/ubuntu/ais/create_mysql_syslog;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;

#Ban list MySQL set up

if [ ! -d /var/lib/mysql/banlist ]; then
    for mysqlCommand in "CREATE DATABASE banlist;" "CREATE USER 'banlist'@'localhost' IDENTIFIED BY 'password';" "GRANT USAGE ON banlist.* to banlist@localhost;" "GRANT ALL PRIVILEGES ON banlist.* to banlist@localhost;" "FLUSH PRIVILEGES;" "USE banlist;" "SOURCE /home/ubuntu/ais/create_mysql_banlist;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;



#Python install

#apt-get install
for i in python-pip python-mysqldb
do
	apt-get install $i -y;
done

#pip install
for i in python-iptables
do
	pip install $i;
done