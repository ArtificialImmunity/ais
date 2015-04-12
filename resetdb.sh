#!/bin/bash

#Botched script to reset the database for testing purposes.


if [ -d /var/lib/mysql/snort ]; then

		for mysqlCommand in "drop database snort;" "drop database archive"
        do
                    echo $mysqlCommand >> mysqlCommands
        done

		mysql -u root -p --password='password'<mysqlCommands
		rm mysqlCommands


        for mysqlCommand in "create database snort;" "create database archive;" "grant usage on snort.* to snort@localhost;" "grant usage on archive.* to snort@localhost;" "set password for snort@localhost=PASSWORD('password');" "grant all privileges on snort.* to snort@localhost;" "grant all privileges on archive.* to snort@localhost;" "flush privileges;" "use snort;" "source /usr/src/create_mysql;"
        do
                    echo $mysqlCommand >> mysqlCommands
        done
#       echo "---------------------------------------------------"
#       echo "  About to change MySQL, enter MySQL credentials."
#       echo "---------------------------------------------------"
        mysql -u root -p --password='password'<mysqlCommands #simple pass for testing purposes only
        rm mysqlCommands
        rm /var/log/snort/*
#        rm /var/log/barnyard2/*

fi;
