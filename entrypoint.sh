#!/bin/bash

echo Setting up iptables...

iptables -t nat -A POSTROUTING -j MASQUERADE

echo Waiting for pipework to give us the eth1 interface...

/opt/coreos-pxe/pipework --wait

echo Starting DHCP+TFTP server...

dnsmasq \
    --no-resolv \
    --no-poll \
    --server=/mydomain/192.168.3.6 \
    --server=8.8.8.8 \
    --server=8.8.4.4 \
    --local=/mydomain/ \
    --interface=eth1 \
    --domain=mydomain,192.168.3.0/24 \
    --dhcp-range=192.168.3.100,192.168.3.200,1h \
    --dhcp-option=3,192.168.3.1 \
    --dhcp-boot=pxelinux.0 \
    --enable-tftp \
    --tftp-root=/srv/tftpboot \
    --dhcp-authoritative \
    --log-queries \
    --log-dhcp \
    --no-daemon
