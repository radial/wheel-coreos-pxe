#!/bin/bash
##----------------
##Name:         run.sh
##Description:  config and installer for dockerfile-coreos-pxe and pipework
##Date:         
##Version:      1.0
##Requirements: wget, docker, pipework
##----------------

# get pipework
wget --no-check-certificate https://raw.github.com/jpetazzo/pipework/master/pipework
chmod +x ./pipework

# build image from dockerfile
sudo docker build -t brianclements/coreos-pxe .

# start container
sudo docker run -d -name=coreos-pxe brianclements/coreos-pxe

# deconfigure eth0, create and configure br0 with eth0's parameters
sudo ./pipework br0 coreos-pxe 192.168.3.6/24
sudo brctl addif br0 eth0
sudo ip addr del 192.168.3.5/24 dev eth0
sudo ip addr add 192.168.3.5/24 dev br0
sudo ip route add default via 192.168.3.1

# confirmation
sudo docker ps
sleep 3s && sudo docker logs coreos-pxe

exit 0
