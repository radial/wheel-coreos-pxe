# Spoke Dockerfile for pxe

FROM            radial/spoke-base:latest
MAINTAINER      Brian Clements <radial@brianclements.net>

# Install packages
ENV             DEBIAN_FRONTEND noninteractive
RUN             apt-get -q update && apt-get -qyV install \
                     dnsmasq wget syslinux host &&\
                apt-get clean

# Set Spoke ID
ENV             SPOKE_NAME pxe

COPY            /entrypoint.sh /entrypoint.sh
