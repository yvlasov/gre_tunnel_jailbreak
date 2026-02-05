#!/bin/bash
export PATH=/root/yandex-cloud/bin:$PATH
source $(dirname $0)/get-env.sh
yc dns zone replace-records --name ${YC_DNS_ZONE_ID} --record "${RU_HOST_FQDN} ${YC_DNS_TTL} A ${MY_PUBLIC_IP}"