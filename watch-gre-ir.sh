#!/bin/bash
source $(dirname $0)/get-env.sh


if ping -c 3 -W 3  $RU_PEER_ADDR > /dev/null ; then 
  echo GRE is UP;
  exit 0
fi

$(dirname $0)/start.sh

