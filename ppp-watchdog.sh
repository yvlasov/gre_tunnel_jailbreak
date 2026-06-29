#!/bin/bash
source "$(dirname "${BASH_SOURCE[0]}")/get-env.sh"
REMOTE_IP=${IR_PEER_ADDR}
REMOTE_ENDPOINT=${IR_HOST_IP}
TUNNEL_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/ppp-ssh.sh"
PIDFILE="/var/run/ppp-tunnel.pid"
# RU_STATIC_ROUTES_EXCEPTIONS

# Set own public IP if DNS not updated yet
export RU_HOST_IP=${MY_PUBLIC_IP}

ipt_mangle="/sbin/iptables -t mangle"

iptables_setup() {
   if [ "$1" == "enable" ]; then
      logger "Applied iptables rules"
      iptables_actions="-D -I"
   elif [ "$1" == "disable" ]; then
      logger "Removed iptables rules"
      iptables_actions="-D"
   else
      echo "Invalid argument to iptables_setup: $1"
      return 1
   fi
   logger "Setting up iptables mangle rules for PPP tunnel traffic"

   # Hook into PREROUTING
   for each_action in ${iptables_actions}; do
      # Masquerade traffic roted over GRE tunnel to ensure return traffic is properly routed back to the host
      iptables -t nat ${each_action} POSTROUTING -o ppp+ -j MASQUERADE >/dev/null 2>&1
      # All containers traffic should be routed over GRE tunnel, exception rules will be applied in the chain
      ${ipt_mangle} ${each_action} PREROUTING -i docker0 -j ROUTE_OVER_PPP >/dev/null 2>&1
      # Route GOOGLE DNS over tunnel
      ${ipt_mangle} ${each_action} PREROUTING -d ${VPN_DNS_IP} -j ROUTE_OVER_PPP >/dev/null 2>&1
      # DNS traffic from host to VPN_DNS_IP (Google DNS) should be routed over GRE tunnel
      ${ipt_mangle} ${each_action} OUTPUT -d ${VPN_DNS_IP} -j ROUTE_OVER_PPP >/dev/null 2>&1
   done
}

init_setup() {
   echo 1 > /proc/sys/net/ipv4/ip_forward
   echo 0 > /proc/sys/net/ipv4/conf/all/rp_filter

   # Setup routing table for VPN tunnel traffic
   ip rule add fwmark ${FW_MARK} lookup ${RT_TABLE_NAME}
   ip route add default via ${IR_PEER_ADDR} dev ppp0 table ${RT_TABLE_NAME}

   # Create chain for routing exceptions
   ${ipt_mangle} -N ROUTE_OVER_PPP
   # Flush existing chain if it exists
   ${ipt_mangle} -F ROUTE_OVER_PPP
   # Network System ports VPN,DNS,etc..
   ${ipt_mangle} -A ROUTE_OVER_PPP -p udp --sport 4500 -j ACCEPT
   ${ipt_mangle} -A ROUTE_OVER_PPP -p udp --sport 500 -j ACCEPT
   ${ipt_mangle} -A ROUTE_OVER_PPP -p udp --sport 1701 -j ACCEPT
   # Local docker trafic routed localy
   ${ipt_mangle} -A ROUTE_OVER_PPP -d 172.16.0.0/12 -j ACCEPT
   # DNS traffic except to VPN_DNS_IP (Google DNS) routed without GRE tunnel
   ${ipt_mangle} -A ROUTE_OVER_PPP -p udp --dport 53 ! -d ${VPN_DNS_IP} -j ACCEPT

   # Populate chain with exception rules
   for each_subnet in ${RU_STATIC_ROUTES_EXCEPTIONS}; do
      ${ipt_mangle} -A ROUTE_OVER_PPP -d ${each_subnet} -j ACCEPT
   done
   # Default action: mark traffic for routing over VPN tunnel
   ${ipt_mangle} -A ROUTE_OVER_PPP -j MARK --set-mark ${FW_MARK}
}

apply_rules() {
   iptables_setup enable
}

remove_rules() {
   iptables_setup disable
}

check_tunnel() {
   ping -c 3 -W 5 "$IR_PEER_ADDR" >/dev/null 2>&1
}

start_tunnel() {
   # Remove old rules first
   remove_rules
   
   # Kill existing tunnel processes
   pkill -f ppp-ssh.sh
   pkill -f "ppp@$REMOTE_ENDPOINT"
   sleep 2
   
   rm -f "$PIDFILE"
   
   # Add static route
   CURRENT_GW=$(ip route | awk '/default/ { print $3; exit }')
   CURRENT_DEV=$(ip route | awk '/default/ { print $5; exit }')
   
   if [ -n "$CURRENT_GW" ] && [ -n "$CURRENT_DEV" ]; then
      ip route add "$REMOTE_ENDPOINT" via "$CURRENT_GW" dev "$CURRENT_DEV" 2>/dev/null
      logger "Added route: $REMOTE_ENDPOINT via $CURRENT_GW dev $CURRENT_DEV"
   fi
   
   # Start tunnel
   sudo -u root "$TUNNEL_SCRIPT" &
   echo $! > "$PIDFILE"
   sleep 15
   
   # Apply rules after tunnel is up
   apply_rules
}

cleanup() {
   remove_rules
   pkill -f ppp-ssh.sh
   rm -f "$PIDFILE"
   exit
}

trap cleanup EXIT INT TERM

trap init_setup EXIT INT TERM

while true; do
   if ! check_tunnel; then
       logger "PPP-SSH tunnel to ${REMOTE_ENDPOINT} down, restarting"
       start_tunnel
   fi
   sleep 30
done
