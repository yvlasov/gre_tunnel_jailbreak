#!/bin/bash
source $(dirname $0)/get-env.sh


echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter
ip link set ${IF_NAME} down
ip tunnel del ${IF_NAME}
ip tunnel add ${IF_NAME} mode gre remote ${RU_HOST_IP} local ${IR_HOST_IP_LOCAL} ttl 127
ip addr add ${IR_PEER_ADDR}/30 peer ${RU_PEER_ADDR}/30 dev ${IF_NAME}
ip link set ${IF_NAME} up multicast off

sleep 5
if ping -c 3 -W 3  $RU_PEER_ADDR > /dev/null ; then 
  echo GRE is UP;
  iptables -t nat -I POSTROUTING 1 -s ${RU_PEER_ADDR} ! -o ${IF_NAME} -j MASQUERADE
  iptables -t filter -I FORWARD 1 -i ${IF_NAME}   -s ${RU_PEER_ADDR} ! -o gre1 -j ACCEPT
  iptables -t filter -I FORWARD 1 ! -i ${IF_NAME} -d ${RU_PEER_ADDR} -o gre1   -j ACCEPT
else
  echo "GRE is DOWN"
  exit 127
fi

