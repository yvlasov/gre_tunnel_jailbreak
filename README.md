# gre_tunnel_jailbreak

```
#/etc/dnsmasq.conf
port=53
listen-address=192.168.0.26,127.0.0.1
bind-interfaces

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
