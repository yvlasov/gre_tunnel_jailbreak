#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/get-env.sh"

if ping -c 3 -W 3  $RU_PEER_ADDR > /dev/null ; then 
  echo ${GRE_IF_NAME^^} is UP;
  exit 0
fi

$(dirname $0)/start-gre-ir.sh

