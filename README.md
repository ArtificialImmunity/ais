# ais
Artifical Immune System for Linux Servers

Author: Jordan Bruce

This is a final year project for University. It is a simple ais system which can be installed on any node of a network. It will capture all network traffic and log it to a local mysql database. Every ~10 seconds, the database is examined to determin if there is any suspicious traffic. If there is, the src IP will be banned. Every ~60 seconds the local database is copied to a central collector database and the local database is flushed. This improves both time when searching, and reduces excess space being used up.
