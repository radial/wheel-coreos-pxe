## Dockerfile-coreos-pxe
Dockerfile and configuration for running dnsmasq as PXE+DHCP server serving Coreos images.

## Setup
* Add your public ssh-key to the file "default" where it says `YOUR-SSH-PUBLIC-KEY-HERE`
* Configure "Dockerfile" by picking your closest ec2 mirror and replacing
  `us-west-1.ec2.archive` with your selection.
* Configure dnsmasq parameters in "entrypoint.sh" to suit your network.
    * Note: DHCP must be deactivated on your router and no other DHCP server can be
      running.
* Double check that the network settings in "run.sh" fit your network as well.
    * Note: I configured my bridge `br0` to "take over" the ip address my `eth0`
      once had and gave the docker container a new IP different from my bridge
      ip. To the network, the container will appear like a completely different
      computer on the LAN while my host keeps it's original ip address.
* Fire it up with `./run.sh`

## License
MIT

## Credits
Much thanks to [Jérôme Petazzoni](https://github.com/jpetazzo) for his help with
[pipework](https://github.com/jpetazzo/pipework), and for
[PXE](https://github.com/jpetazzo/pxe) which this container is mainly based off
of. 
