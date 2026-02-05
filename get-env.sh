#!/bin/bash

export MY_PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)

export IF_NAME='gre1'
export FW_MARK='0x15'
export RT_TABLE_NAME='tableX'

# RU YACLOUD
export RU_HOST_FQDN="vpn-ru.pytn.ru."
export RU_HOST_IP=$MY_PUBLIC_IP
export RU_HOST_IP_LOCAL=10.129.0.24
export RU_PEER_ADDR=172.31.1.1
export YC_DNS_TTL=20
export YC_DNS_ZONE_ID="vpn-ru-zone"

# IRELAND AWS
export IR_HOST_IP=34.244.227.121
export IR_HOST_IP_LOCAL=172.31.30.243
export IR_PEER_ADDR=172.31.1.2

