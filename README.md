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

Fix Docker vs dnsmasq startup order problem fixed by *bind-dynamic*

```bash
sudo apt install dnsmasq
sudo systemctl restart dnsmasq
```

```ini
#/etc/dnsmasq.conf for Yandex Cloud server
port=53
# listen-address=172.17.0.1 # Docker host 
bind-dynamic
except-interface=lo

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
ssh -J ubuntu@34.244.227.121 yvlasov@10.255.255.3
```


```
#/etc/dnsmasq.conf
port=53
#listen-address=192.168.1.210,127.0.0.1,10.255.255.2
#bind-interfaces

# Route specific domains to specific DNS servers
server=/youtube.com/8.8.8.8
server=/google.com/8.8.8.8
server=/goo.gl/8.8.8.8
server=/bdn.dev/8.8.8.8
server=/g.co/8.8.8.8
server=/youtu.be/8.8.8.8
server=/yt.be/8.8.8.8
server=/youtubekids.com/8.8.8.8
server=/ytimg.com/8.8.8.8
server=/facebook.com/8.8.8.8
server=/instagram.com/8.8.8.8
server=/cdninstagram.com/8.8.8.8
server=/wa.me/8.8.8.8
server=/whatsapp.com/8.8.8.8
server=/telegram.com/8.8.8.8
server=/apple.com/8.8.8.8

# Default upstream
server=77.88.8.8
server=77.88.8.1

# Cache settings
cache-size=1000
```

## Forticlient VPN
```bash
sudo apt update
sudo apt install openfortivpn 
```

## CheckPoint VPN

```bash
sudo curl -fsSL -o /etc/apt/sources.list.d/snx-rs.sources \
  https://ancwrd1.github.io/snx-rs/snx-rs.sources
sudo apt update
sudo apt install snx-rs
```

```bash
mkrir -p ~/.config/snx-rs/
cat << EOF > ~/.config/snx-rs/snx-rs.conf
login-type=vpn_Indeed
user-name=U_M34PU
#password=<skipping..>
server-name=217.12.96.114
ignore-server-cert=true
log-level=warning
#trace
#transport-type=udp
tunnel-type=ssl
no-dns=true
EOF
```

```bash
snxctl connect

snxctl disconnect
# DNS servers: [10.226.0.5, 10.224.0.5]
# Search domains: [moscow.alfaintra.net, alfaintra.net]
```


```bash
rm /etc/resolv.conf   # remove the symlink
cat << 'EOF' > /etc/resolv.conf 
nameserver 10.226.0.5
nameserver 10.224.0.5
options edns0
search moscow.intra.net
EOF
```

```bash
sudo apt install dante-server

cat << EOF > /etc/danted.conf 
logoutput: stderr
internal: 0.0.0.0 port = 1080
external: snx-tun
clientmethod: none
socksmethod: none
user.unprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error
}
EOF

sudo systemctl enable --now danted
```
### Setup proxy routing in chrome

https://chromewebstore.google.com/detail/proxy-switchyomega-v3/hihblcmlaaademjlakdpicchbjnnnkbo


```bash
# Debug commands
ip rule

curl -v --proxy socks5h://192.168.139.116:1080 https://owa.intra.net/
```
