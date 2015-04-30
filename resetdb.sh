#!/bin/bash

#Script to reset the database
#Should be called once current MySQL data is sent to collector


if [ -d /var/lib/mysql/snort ]; then

    for mysqlCommand in "DROP DATABASE snort;" "DROP DATABASE archive;" "DROP DATABASE syslog;"
    do
                echo $mysqlCommand >> mysqlCommands
    done

    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands


    for mysqlCommand in "CREATE DATABASE snort;" "CREATE DATABASE archive;" "GRANT USAGE ON snort.* to snort@localhost;" "GRANT USAGE ON archive.* to snort@localhost;" "set password for snort@localhost=PASSWORD('password');" "GRANT ALL PRIVILEGES ON snort.* to snort@localhost;" "GRANT ALL PRIVILEGES ON archive.* to snort@localhost;" "FLUSH PRIVILEGES;" "USE snort;" "SOURCE /usr/src/create_mysql;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
    rm /var/log/snort/*
#   rm /var/log/barnyard2/*

fi;

#SysLog MySQL set up

if [ ! -d /var/lib/mysql/syslog ]; then

    for mysqlCommand in "DROP DATABASE syslog;"
    do
                echo $mysqlCommand >> mysqlCommands
    done

    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands


    for mysqlCommand in "CREATE DATABASE syslog;" "CREATE USER 'syslog'@'localhost' IDENTIFIED BY 'password';" "GRANT USAGE ON syslog.* to syslog@localhost;" "GRANT ALL PRIVILEGES ON syslog.* to syslog@localhost;" "FLUSH PRIVILEGES;" "USE syslog;" "SOURCE /home/ubuntu/ais/create_mysql_syslog;"
    do
            echo $mysqlCommand >> mysqlCommands
    done
    mysql -u root -p --password='password'<mysqlCommands
    rm mysqlCommands
fi;
