#!/bin/bash
## Cron setup
## m h  dom mon dow   comman
#@reboot /root/update-dns.sh
#@reboot /root/tunnel/start-gre.sh

sleep 3
#set -x

source "$(dirname "${BASH_SOURCE[0]}")/get-env.sh"

# Set own public IP if DNS not updated yet
export RU_HOST_IP=${MY_PUBLIC_IP}

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter

echo "Restarting GRE tunnel ${GRE_IF_NAME} with remote ${IR_HOST_IP} and local ${RU_HOST_IP_LOCAL}"
ip link set ${GRE_IF_NAME} down
ip tunnel del ${GRE_IF_NAME}
ip tunnel add ${GRE_IF_NAME} mode gre remote ${IR_HOST_IP} local ${RU_HOST_IP_LOCAL} ttl 127
ip addr add ${RU_PEER_ADDR}/30 peer ${IR_PEER_ADDR}/30 dev ${GRE_IF_NAME}
ip link set ${GRE_IF_NAME} up multicast off

iptables -t nat -I POSTROUTING 1 -o ${GRE_IF_NAME} -j MASQUERADE

ipt_mangle="/sbin/iptables -t mangle"

echo "Setting up iptables mangle rules for ${GRE_IF_NAME^^} tunnel traffic"
# Create chain for routing exceptions
${ipt_mangle} -N ROUTE_OVER_${GRE_IF_NAME^^}
# Flush existing chain if it exists
${ipt_mangle} -F ROUTE_OVER_${GRE_IF_NAME^^}

# Hook into PREROUTING
for each_action in "-D" "-I" ; do
  # All containers traffic should be routed over GRE tunnel, exception rules will be applied in the chain
  ${ipt_mangle} ${each_action} PREROUTING -i docker0 -j ROUTE_OVER_${GRE_IF_NAME^^}
  # DNS traffic from host to Google DNS should be routed over GRE tunnel
  ${ipt_mangle} ${each_action} PREROUTING ! -i docker0 -p udp -d 8.8.8.8/32 -m udp --dport 53 -j MARK --set-mark ${FW_MARK}
  ${ipt_mangle} ${each_action} PREROUTING ! -i docker0 -p udp -d 8.8.8.8/32 -m udp --dport 53 -j MARK --set-mark ${FW_MARK}
done

# Populate chain with exception rules
# Gosuslugi
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -d 213.59.252.0/22 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -d 87.0.0.0/8 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -d 91.206.127.0/24 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -d 185.71.66.0/24 -j ACCEPT
# Network System ports VPN,DNS,etc..
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -p udp --sport 4500 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -p udp --sport 500 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -p udp --sport 1701 -j ACCEPT
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -p udp --dport 53 ! -d 8.8.8.8 -j ACCEPT

# Default action: mark traffic
${ipt_mangle} -A ROUTE_OVER_${GRE_IF_NAME^^} -j MARK --set-mark ${FW_MARK}

ip rule add fwmark ${FW_MARK} lookup ${RT_TABLE_NAME}
ip route add default via ${RU_PEER_ADDR} dev ${GRE_IF_NAME} table ${RT_TABLE_NAME}

