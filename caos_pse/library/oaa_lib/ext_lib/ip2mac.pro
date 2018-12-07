;$Id: ip2mac.pro,v 1.3 2007/04/13 09:19:54 marco Exp $$
;+
; NAME:
;    IP2MAC
;
; PURPOSE:
;    Get locals MAC addresses.
;
; USAGE:
;    err = ip2mac(ip, MAC=mac, MYIP=myip)
;
; INPUT: 
;    ip: IP number to analyze (like 192.168.0.54)
;
; OUTPUT: 
;    err: if 0 all done, if -1 an error was occurred.
;    mac: MAC of local network board passing through (like 00:40:F4:8D:88:44)
;    myip: IP address of local network board (like 192.168.0.100)
;
; DEPENDENCIES:
;    eth.py script  (PYTHON ver 2.4 or greater, WINDOWS not yet tested)
;
;-


Function ip2mac, ip, MAC=mac, MYIP=myip

    command = file_which('eth.py')
    spawn, command + " " + ip, str
    if str[0] eq -1 or str[1] eq -1 then return, -1 
    myip = str[1]
    mac = str[0]
    return, 0

End
