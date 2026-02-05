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

echo "Restarting GRE tunnel ${IF_NAME} with remote ${IR_HOST_IP} and local ${RU_HOST_IP_LOCAL}"
ip link set ${IF_NAME} down
ip tunnel del ${IF_NAME}
ip tunnel add ${IF_NAME} mode gre remote ${IR_HOST_IP} local ${RU_HOST_IP_LOCAL} ttl 127
ip addr add ${RU_PEER_ADDR}/30 peer ${IR_PEER_ADDR}/30 dev ${IF_NAME}
ip link set ${IF_NAME} up multicast off

iptables -t nat -I POSTROUTING 1 -o ${IF_NAME} -j MASQUERADE

ipt_mangle="/sbin/iptables -t mangle"

echo "Setting up iptables mangle rules for ${IF_NAME^^} tunnel traffic"
# Create chain for routing exceptions
${ipt_mangle} -N ROUTE_OVER_${IF_NAME^^}
# Flush existing chain if it exists
${ipt_mangle} -F ROUTE_OVER_${IF_NAME^^}

# Populate chain with exception rules
# Gosuslugi
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -d 213.59.252.0/22 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -d 87.0.0.0/8 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -d 91.206.127.0/24 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -d 185.71.66.0/24 -j ACCEPT
# Network System ports VPN,DNS,etc..
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -p udp --sport 4500 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -p udp --sport 500 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -p udp --sport 1701 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -p udp --dport 53 -j ACCEPT

# Default action: mark traffic
${ipt_mangle} -A ROUTE_OVER_${IF_NAME^^} -j MARK --set-mark ${FW_MARK}

# Hook into PREROUTING
${ipt_mangle} -I PREROUTING 1 -i docker0 -j ROUTE_OVER_${IF_NAME^^}

ip rule add fwmark ${FW_MARK} lookup ${RT_TABLE_NAME}
ip route add default via ${RU_PEER_ADDR} dev ${IF_NAME} table ${RT_TABLE_NAME}

