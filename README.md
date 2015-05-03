# ais
<h1>Artifical Immune System for Linux Servers<h1>

Author: <i>Jordan Bruce</i>

This is a final year project for University. It is a simple ais system which can be installed on a node in a network. For testing purposes I have been using an Ubuntu Server 14.0.4 LTS. 

It will capture all network traffic and log it to a local mysql database. Every ~60 seconds (depending on crontab configurations), the database is examined by the python code to determine if there is any suspicious traffic (ping flood, ssh brute force, directory scans). If there is, the src IP will be banned. After the 60 seconds are up, the local database is copied to a central collector database and the local database is flushed. This improves both time when searching, and reduces excess space being used up. The collector will then look at the global ban list to see if there is one IP that is constantly being banned, if this is the case, the collector will signal all the other agents to ban that IP also.

<h2>To set up<h2>

<b><i>It is STRONGLY recommended that you only install this if you are using a fresh install of Ubuntu Server and that you know what the code is doing. An uninstall script has not been created, and as such, I will not be held responsible for any changes you make to you own system as a result of this code</i></b>

Now all the serious stuff is out the way. You can download the git repository:
Due to the nature of the ais, make sure that the ais code is ran in /usr/local/src/

From the collector, you should deploy an agent on a node using the deploy script. Source code can be found at:

<code>git clone https://github.com/ArtificialImmunity/ais</code>

The agent deploy script will:
    <li>Install dependencies for Snort, Barnyard, MySQL, and Python</li>
    <li>Configure necessary files for the aforementioned programs</li>
    <li>Set crontab timers for netagent.py and sysagent.py</li>
    <li>Run automatically in the background</li>

The agent will run snort and barnyard2 to monitor and collect network traffic to the MySQL database according to the snort rules and system python script.

The netagent.py and sysagent.py will be added to the crontab and ran on the minute, every minute

The agent will automatically send IPs that have been banned to the collector, the collector will look for IPs that have banned multiple times, over all agents, and set a global ban on IPs with repeated convictions
