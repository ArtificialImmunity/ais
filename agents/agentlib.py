import struct
import socket
import netifaces as ni
import MySQLdb

#Convert hex to string (used for packet analysis)
def hexToString(data):
    return ''.join(chr(int(data[i:i+2], 16)) for i in range(0, len(data), 2))

#Converts ip from 32 bit integer to 4 dotted octets
def ipDecToOct(data):
    t = struct.pack("!I", data)
    return socket.inet_ntoa(t)

#Converts string from dotted ip to 32 bit int
def octToIpDec(data):
    return reduce(lambda a,b: a<<8 | b, map(int, data.split(".")))

def updateBanList(banlist, mysqlhost, mysqluser, mysqlpass,mysqldb, dstip, reason):

        con = MySQLdb.Connection(host=mysqlhost, user=mysqluser, passwd=mysqlpass, db=mysqldb)

        cur = con.cursor()

        for ip in banlist:
            #SQL query to INSERT all banned IPs into database .
            cur.execute('''INSERT into bannedIPs (ip_src, ip_dst, reason, timestamp)\
                        values (%s, %s, %s, now())''',(octToIpDec(ip), octToIpDec(dstip), reason))

            # Commit changes in the database
            con.commit()

        con.close()
        return

def getThisIP():
    ni.ifaddresses('eth0')
    return ni.ifaddresses('eth0')[2][0]['addr']

def main():
    return


if __name__ == '__main__':
    main()