#!/usr/bin/python
import MySQLdb
import sys
from datetime import datetime
import iptc

allIP = []
ips = {'127.0.0.1' : 0}
banIP = []

def get404():
    #crontab runs on the minute
    #this get the minute that it just was
    now = datetime.now()
    currentMinute = now.minute-1
     #cycle through lines of apache2 access log in reverse order
    for lines in reversed(open("/var/log/apache2/access.log", "r").readlines()):
        #search apache log for 404 errors
        if '404' in lines:
            line = lines.split(" ")
            time = line[3].split(":")
            #get the minute the log was made
            minute = int(time[2])

            #print "Minute = " + str(minute)
            #print "Current Minute = " + str(currentMinute)

            #if it's over the last 60 seconds, break
            if currentMinute != minute:
                break
            else:
                #else put the 404 error ip in ip list
                allIP.append(line[0])


    for allips in allIP: #cycle through all ips found
        if allips in ips:
            ips[allips] = ips[allips] + 1 #count No times for each ip
        else:
            ips[allips] = 1 #else create new dict entry
    return ips

#Puts ip in ban list if number of ping requests is over the threshold
def dirScan():
    threshold = 1 #threshold for 404 errors allowed per minute
    for ip in ips:
        if ips[ip] > threshold:#if ip 404 errors is over threshold, add to ban list
            banIP.append(ip)

def ban404Scan():
    #cycle through ban list
    for ip in banIP:
        #make an IPTables rule for the ban ip on port 80 (HTTP)
        chain = iptc.Chain(iptc.Table(iptc.Table.FILTER), "INPUT")
        rule = iptc.Rule()
        rule.in_interface = "eth0"
        rule.src = ip
        rule.protocol = "tcp"
        match = iptc.Match(rule, "tcp")
        match.dport = "80"
        rule.add_match(match)
        target = iptc.Target(rule, "DROP")
        rule.target = target
        chain.insert_rule(rule)

def main():
    get404()
    dirScan()
    ban404Scan()
    print ips
    return


if __name__ == '__main__':
    main()