#!/bin/bash
export PATH=/root/yandex-cloud/bin:$PATH
FQDN="vpn-ru.pytn.ru."
TTL=20
YC_DNS_ZONE="vpn-ru-zone"
MY_PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
yc dns zone replace-records --name ${YC_DNS_ZONE} --record "${FQDN} $TTL A ${MY_PUBLIC_IP}"

