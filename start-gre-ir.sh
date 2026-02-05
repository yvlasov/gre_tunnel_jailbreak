#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/get-env.sh"

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter

ip link set ${GRE_IF_NAME} down
ip tunnel del ${GRE_IF_NAME}
ip tunnel add ${GRE_IF_NAME} mode gre remote ${RU_HOST_IP} local ${IR_HOST_IP_LOCAL} ttl 127
ip addr add ${IR_PEER_ADDR}/30 peer ${RU_PEER_ADDR}/30 dev ${GRE_IF_NAME}
ip link set ${GRE_IF_NAME} up multicast off

for each_action in "-D" "-I" ; do
  iptables -t nat ${each_action} POSTROUTING -s ${RU_PEER_ADDR} ! -o ${GRE_IF_NAME} -j MASQUERADE
  iptables -t filter ${each_action} FORWARD -i ${GRE_IF_NAME}   -s ${RU_PEER_ADDR} ! -o ${GRE_IF_NAME} -j ACCEPT
  iptables -t filter ${each_action} FORWARD ! -i ${GRE_IF_NAME} -d ${RU_PEER_ADDR} -o ${GRE_IF_NAME}   -j ACCEPT
  iptables -t filter ${each_action} FORWARD -d ${RU_PEER_ADDR} ! -i ${GRE_IF_NAME} -o ${GRE_IF_NAME}   -j ACCEPT
  iptables -t filter ${each_action} FORWARD -s ${RU_PEER_ADDR} -i ${GRE_IF_NAME} ! -o ${GRE_IF_NAME}   -j ACCEPT
 
  # SSH-PPP vpn clients traffic rules
  iptables -t filter ${each_action} FORWARD ! -s 10.255.255.0/30 -d 10.255.255.0/30 -j ACCEPT
  iptables -t filter ${each_action} FORWARD -s 10.255.255.0/30 ! -d 10.255.255.0/30 -j ACCEPT
  iptables -t nat ${each_action} POSTROUTING -s 10.255.255.0/30 ! -d 10.255.255.0/30 -j MASQUERADE

  iptables -t mangle ${each_action} PREROUTING -i ppp+ -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1460
  iptables -t mangle ${each_action} FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

  # Docker containers VPN ports
  #iptables -t nat ${each_action} DOCKER ! -i docker0 -p udp -m udp --dport 4500 -j DNAT --to-destination 172.17.0.2:4500
  #iptables -t nat ${each_action} DOCKER ! -i docker0 -p udp -m udp --dport 500 -j DNAT --to-destination 172.17.0.2:500
  #iptables -t nat ${each_action} DOCKER ! -i docker0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 172.17.0.3:443

done

sleep 5
if ping -c 3 -W 3  $RU_PEER_ADDR > /dev/null ; then 
  echo "${GRE_IF_NAME^^} from ${IR_HOST_IP} to ${RU_HOST_IP} is UP"
else
  echo "${GRE_IF_NAME^^} is DOWN"
  exit 127
fi

