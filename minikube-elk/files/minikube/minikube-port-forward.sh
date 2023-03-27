#!/bin/bash

iptables -t nat -A PREROUTING -p tcp --dport 9200 -j DNAT --to-destination 192.168.49.2:30090
iptables -t nat -A PREROUTING -p tcp --dport 5601 -j DNAT --to-destination 192.168.49.2:30091
iptables -t nat -A PREROUTING -p tcp --dport 8200 -j DNAT --to-destination 192.168.49.2:30092

iptables -A FORWARD -p tcp -d 192.168.49.2/32 --dport 30090 -j ACCEPT
iptables -A FORWARD -p tcp -d 192.168.49.2/32 --dport 30091 -j ACCEPT
iptables -A FORWARD -p tcp -d 192.168.49.2/32 --dport 30092 -j ACCEPT

