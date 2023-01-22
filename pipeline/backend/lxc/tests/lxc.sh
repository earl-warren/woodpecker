#!/bin/sh -ex

apt-get install -y -qq make git libvirt0 libpam-cgfs bridge-utils uidmap dnsmasq-base dnsmasq dnsmasq-utils qemu-user-static
systemctl stop dnsmasq
systemctl disable dnsmasq
apt-get install -y -qq lxc
systemctl stop lxc-net
cat >> /etc/default/lxc-net <<'EOF'
LXC_ADDR="10.0.5.1"
LXC_NETMASK="255.255.255.0"
LXC_NETWORK="10.0.5.0/24"
LXC_DHCP_RANGE="10.0.5.2,10.0.5.254"
LXC_DHCP_MAX="253"
EOF
systemctl start lxc-net
systemctl status

wget --quiet -c https://go.dev/dl/go1.19.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.19.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/woodpecker/go
export HOME=/woodpecker

make build-cli && ./dist/woodpecker-cli exec --backend-engine=lxc --local=true --log-level=trace pipeline/backend/lxc/tests/simple.yml
