# CoreOS dchp+tftp pxe server
#
# Version   1.0
FROM        stackbrew/ubuntu:saucy
MAINTAINER  Brian Clements <brian@brianclements.net>

# Select your closest mirror from...
# East Coast US:                        us-east-1.ec2.archive
# West Coast US (California):           us-west-1.ec2.archive
# West Coast US (Oregon):               us-west-2.ec2.archive
# South America (São Paulo, Brazil):    sa-east-1.ec2.archive
# Western Europe (Dublin, Ireland):     eu-west-1.ec2.archive
# SouthEast Asia (Singapore):           ap-southeast-1.ec2.archive
# NorthEast Asia (Tokyo):               ap-northeast-1.ec2.archive
# ... and replace MIRROR below with your selection
RUN         sed 's@archive@us-west-1.ec2.archive@' -i /etc/apt/sources.list

# Install packages
RUN         apt-get -q update
RUN         apt-get -qy install dnsmasq wget syslinux iptables

# Add launch script
ADD         entrypoint.sh /opt/coreos-pxe/entrypoint.sh
RUN         chmod +x /opt/coreos-pxe/entrypoint.sh

# Install pipework
WORKDIR     /opt/coreos-pxe
RUN         wget --no-check-certificate -nv https://raw.github.com/jpetazzo/pipework/master/pipework
RUN         chmod +x pipework

# Configure TFTP
ADD         default /srv/tftpboot/pxelinux.cfg/default
RUN         cp /usr/lib/syslinux/pxelinux.0 /srv/tftpboot/
WORKDIR     /srv/tftpboot
RUN         wget -nv http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_pxe.vmlinuz
RUN         wget -nv http://storage.core-os.net/coreos/amd64-generic/dev-channel/coreos_production_pxe_image.cpio.gz
RUN         chmod -R 777 /srv/tftpboot
RUN         chown -R nobody: /srv/tftpboot

ENTRYPOINT  ["/opt/coreos-pxe/entrypoint.sh"]
