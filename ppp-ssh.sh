#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/get-env.sh"

PIPE="/tmp/ppp-pipe"

cleanup() {
   rm -f "$PIPE"
   exit
}

trap cleanup EXIT INT TERM

# Create named pipe
mkfifo "$PIPE"

# Start SSH connection in background
ssh -o Compression=no \
   -o ServerAliveInterval=30 \
   -o ServerAliveCountMax=3 \
   -o ConnectTimeout=10 \
   -o ExitOnForwardFailure=yes \
   ppp@${IR_HOST_IP} "sudo pppd nodetach notty noauth file /etc/ppp/options.server.${RU_PEER_ADDR##*.}" \
   < "$PIPE" | pppd nodetach notty noauth file /etc/ppp/options.client > "$PIPE"

