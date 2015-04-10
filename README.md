# ais
Artifical Immune System for Linux Servers

Author: Jordan Bruce

This is a final year project for University. It is a simple ais system which can be installed on a node in a network. For testing purposes I have been using an Ubuntu Server 14.0.4 LTS. 

It will capture all network traffic and log it to a local mysql database. Every ~60 seconds, the database is examined by the python code to determin if there is any suspicious traffic. If there is, the src IP will be banned. After the 60 seconds are up, the local database is copied to a central collector database (not implimented yet) and the local database is flushed. This improves both time when searching, and reduces excess space being used up.

