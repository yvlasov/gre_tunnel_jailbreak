# gre_tunnel_jailbreak

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
```bash
 ssh -J ubuntu@34.244.227.121 10.255.255.3
```

```
#/etc/dnsmasq.conf
port=53
#listen-address=192.168.0.26,127.0.0.1
#bind-interfaces

# Route specific domains to specific DNS servers
server=/youtube.com/8.8.8.8
server=/google.com/8.8.8.8
server=/goo.gl/8.8.8.8
server=/facebook.com/8.8.8.8
server=/instagram.com/8.8.8.8
server=/cdninstagram.com/8.8.8.8


# Default upstream
server=192.168.0.1

# Cache settings
cache-size=1000
```
