#!/usr/bin/python
# -*- coding: utf-8 -*-

import MySQLdb
import sys
import struct
import socket
import iptc

allIP = []
ips = {'127.0.0.1' : 0}
thisIP = '192.168.224.137'
banIP = []

#Convert hex to string (used for packet analysis)
def hexToString(data):
    return ''.join(chr(int(data[i:i+2], 16)) for i in range(0, len(data), 2))

#Converts ip from 32 bit integer to 4 dotted octets
def ipDecToOct(data):
    t = struct.pack("!I", data)
    return socket.inet_ntoa(t)


def getSrcCount():
    for ip in allIP: #cycle through all ips found
        if ip in ips:
            ips[ip] = ips[ip] + 1 #count No times for each ip
        else:
            ips[ip] = 1 #else create new dict entry
    return

#Old ip function with limit instead of time
def updateIPs():
    con = MySQLdb.Connection(host='localhost', user='root', passwd='password', db='snort')

    cur = con.cursor()

    cur.execute("SELECT * FROM (\
                    SELECT * FROM iphdr ORDER BY cid DESC LIMIT 100\
                ) sub\
                ORDER BY cid ASC")
    #cur.execute("SELECT * FROM iphdr")

    for row in cur.fetchall():
        ip = ipDecToOct(row[2])
        if ip != thisIP:
            allIP.append(ipDecToOct(row[2]))

    if con:
        con.close()
    return

#Puts ip in ban list if number of ping requests is over the threshold
def icmpPingFlood():
    threshold = 10
    for ip in ips:
        if ips[ip] > threshold:
            banIP.append(ip)

#Adds rule to IPTables if ip is in the ban list
def banICMPFlood():
    for ip in banIP:
        chain = iptc.Chain(iptc.Table(iptc.Table.FILTER), "INPUT")
        rule = iptc.Rule()
        rule.in_interface = "eth0"
        rule.src = ip
        rule.protocol = "icmp"
        target = iptc.Target(rule, "DROP")
        rule.target = target
        chain.insert_rule(rule)

#Gets all ICMP packets from database (from snort alerts)
def fetchIPs():
    con = MySQLdb.Connection(host='localhost', user='root', passwd='password', db='snort')

    cur = con.cursor()

    cur.execute("SELECT event.cid, iphdr.ip_src, iphdr.ip_dst, event.timestamp\
                FROM iphdr\
                INNER JOIN event\
                ON event.cid=iphdr.cid\
                WHERE timestamp > date_sub(now(), interval 60 second);")

    for row in cur.fetchall():
        print row[1]
        ip = ipDecToOct(row[1])
        if ip != thisIP:
            allIP.append(ip)

    if con:
        con.close()
    return





def main():
    print "Fetching MySQL entries..."
    fetchIPs()
    print "Caclulating IP ICMP quantity..."
    getSrcCount()
    print "- All IPs with ICMP amount -"
    print ips
    print "Adding IPs to ban list..."
    icmpPingFlood()
    print "- Banned IPs -"
    print banIP
    print "Adding iptables rules for banned IPs..."
    banICMPFlood()
    print "Done"

    return

if __name__ == '__main__':
    main()
