#!/usr/bin/python

# Usage: eth.py 193.206.155.4
# Get mac address on thernet interface used to communicate with IP address given and the local IP address.
# L.Fini, 2/4/2007
# M.Xompero, 12/4/2007


debug=0   # Set to 1 for verbose output

cmd1='/sbin/route '
cmd2='/sbin/ifconfig '

import pdb
import sys,os
import re
import socket

def tobin(ip):
  a=ip.split('.')
  ret= int(a[3])+int(a[2])*256+int(a[1])*65536+int(a[0])*16777216
  return ret

def ipmask(ip,mask):
  ipa=tobin(ip)
  mka=tobin(mask)
  mskd=(ipa&mka)
  ret1=int(mskd/16777216)
  mskd=mskd%16777216
  ret2=int(mskd/65536)
  mskd=mskd%65536
  ret3=int(mskd/256)
  ret4=mskd%256
  ret="%d.%d.%d.%d" % (ret1,ret2,ret3,ret4)
  return ret

def getIface(ip):
  nmb=ip.split('.')[0]
  ln=len(nmb)
  inp=os.popen(cmd1)
  found=None
  while 1:
    l=inp.readline()
    if not l: break
    if l[:ln]==nmb:
      a=re.split('\s+',l)
      route,mask,iface=a[0],a[2],a[7]
      if debug: print "route to",route,"with mask",mask,"through",iface
      if ipmask(route,mask)==ipmask(ip,mask): found=iface

  if debug: print "Route to:",ip,"through:",found
  inp.close()
  return found

def main():
  
  if len(sys.argv) == 1:
    print "Get MAC address on thernet interface used to communicate with IP address given and the local IP address"
    print "Usage: eth.py  IP_ADDR"
    print "History:"
    print "  L.Fini, 2/4/2007"
    print "  M.Xompero, 12/4/2007"
    return
    
  ip=sys.argv[1]
  iface=getIface(ip)

  if iface:
    inp=os.popen(cmd2 + iface)
    l=inp.readline()
    a=re.split('\s+',l)
    mac=a[4]
    l=inp.readline()
    b = re.split('[\s:]+',l)
    myip = b[3]
  else:
    mac='-1'
    myip='-1'

  if debug:
    print "Macaddress to:",ip," :",mac
    print "My IP is:", myip
  else:
    print mac
    print myip
    
  

  
if __name__=='__main__': main()
