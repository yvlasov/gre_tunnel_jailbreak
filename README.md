# Personal VPN infrastructure *l2tp/GRE/ssh-ppp*

## RU server

### RU server Client l2tp vpn 
See details:
* https://github.com/hwdsl2/setup-ipsec-vpn/

```bash
docker run \
    --name vpn-l2tp \
    --env-file ./vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```
### RU server DNS request routing using dnsmasq

```
#/etc/dnsmasq.conf for Yandex Cloud server
port=53
listen-address=172.17.0.1 # Docker host 

server=/youtube.com/8.8.8.8
server=/google.com/8.8.8.8
server=/goo.gl/8.8.8.8
server=/facebook.com/8.8.8.8
server=/instagram.com/8.8.8.8
server=/cdninstagram.com/8.8.8.8

server=127.0.0.53

cache-size=1000
```


## IR Server

### IR Server SSH-PPP VPN Client

```bash
# Connect to Zaitsevs RPI
ssh -J ubuntu@34.244.227.121 10.255.255.3
```

