#!/bin/bash
## Cron setup
## m h  dom mon dow   comman
#@reboot /root/update-dns.sh
#@reboot /root/tunnel/start-gre.sh

sleep 3
set -x

source $(dirname $0)/get-env.sh

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
ip link set ${IF_NAME} down
ip tunnel del ${IF_NAME}
ip tunnel add ${IF_NAME} mode gre remote ${IR_HOST_IP} local ${RU_HOST_IP_LOCAL} ttl 127
ip addr add ${RU_PEER_ADDR}/30 peer ${IR_PEER_ADDR}/30 dev ${IF_NAME}
ip link set ${IF_NAME} up multicast off


iptables -t nat -I POSTROUTING 1 -o ${IF_NAME} -j MASQUERADE
# Gosuslugi
iptables -t mangle -I PREROUTING -d 213.59.252.0/22 -i docker0 -j ACCEPT
iptables -t mangle -I PREROUTING -d 87.0.0.0/8 -i docker0 -j ACCEPT
iptables -t mangle -I PREROUTING -d 91.206.127.0/24 -i docker0 -j ACCEPT
iptables -t mangle -I PREROUTING -d 185.71.66.0/24 -i docker0 -j ACCEPT
iptables -t mangle -I PREROUTING 1 -i docker0 -p udp -m udp --sport 4500 -j ACCEPT
iptables -t mangle -I PREROUTING 1 -i docker0 -p udp -m udp --sport 500 -j ACCEPT
iptables -t mangle -I PREROUTING 1 -i docker0 -p udp -m udp --sport 1701 -j ACCEPT
iptables -t mangle -I PREROUTING 1 -i docker0 -p udp -m udp --dport 53 -j ACCEPT
iptables -t mangle -A PREROUTING -i docker0 -j MARK --set-mark 0x15


ip rule add fwmark 0x15 lookup tableX
ip route add default via ${RU_PEER_ADDR} dev ${IF_NAME} table tableX

