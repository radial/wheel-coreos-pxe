#!/bin/bash
##----------------
##Name:         resume.sh
##Description:  resume coreos-pxe boot container after host restart
##Date:         
##Version:      1.0
##Requirements: wget, docker, pipework
##----------------

## docker restarts all containers that were previously running
## so we are assuming coreos-pxe already running. Uncomment this next line
## if it is not.
# sudo docker start coreos-pxe

## restart pipework
sudo ./pipework br0 coreos-pxe 192.168.3.6/24

sudo docker ps
sleep 3s && sudo docker logs coreos-pxe

exit 0
