#!/bin/bash
set -e

# Tunable settings
REFRESH_IMAGES=${REFRESH_IMAGES:-"True"}
CACHE_IMAGES=${CACHE_IMAGES:-"True"}
RELEASE=${RELEASE:-stable}
SRV_DIR=${SRV_DIR:-/data/tftpboot}
CONF_FILE=${CONF_FILE:-/config/dnsmasq.conf}
DNS_CHECK=${DNS_CHECK:-"False"}
AMMEND_IMAGE=${AMMEND_IMAGE:-''}

# Misc settings
ERR_LOG=/log/$HOSTNAME/pxe_stderr.log
CACHE_DIR=/data/cache/$RELEASE


restart_message() {
    echo "Container restart on $(date)."
    echo -e "\nContainer restart on $(date)." | tee -a $ERR_LOG
}

get_signing_key() {
    if [ ! -e /data/cache/CoreOS_Image_Signing_Key.pem ]; then
        wget -P /data/cache http://coreos.com/security/image-signing-key/CoreOS_Image_Signing_Key.pem
    else
        echo "Signing key already downloaded." | tee -a $ERR_LOG
    fi
}

prep_dirs() {
    mkdir -p $SRV_DIR
    ln -sf /config/pxelinux.cfg $SRV_DIR/pxelinux.cfg
    cp /usr/lib/syslinux/pxelinux.0 $SRV_DIR
    mkdir -p /data/cache
}

get_images() {
    rm -rf "$CACHE_DIR"
    mkdir -p "$CACHE_DIR"
    cd "$CACHE_DIR"
    echo -n "Downloading \"$RELEASE\" channel pxe files..." | tee -a $ERR_LOG
    wget -nv http://${RELEASE}.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz 
    wget -nv http://${RELEASE}.release.core-os.net/amd64-usr/current/coreos_production_pxe.vmlinuz.sig
    wget -nv http://${RELEASE}.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz 
    wget -nv http://${RELEASE}.release.core-os.net/amd64-usr/current/coreos_production_pxe_image.cpio.gz.sig 
    echo "done" | tee -a $ERR_LOG

    gpg --import /data/cache/CoreOS_Image_Signing_Key.pem
    if ! $(gpg --verify coreos_production_pxe.vmlinuz.sig && gpg --verify coreos_production_pxe_image.cpio.gz.sig); then
        echo "Image verification failed. Aborting container start." | tee -a $ERR_LOG
        exit 1
    fi
}

apply_permissions() {
    chmod -R 777 $SRV_DIR $CACHE_DIR
    chown -R nobody: $SRV_DIR $CACHE_DIR
}

select_image() {
    ln -sf $CACHE_DIR/coreos_production_pxe.vmlinuz $SRV_DIR/coreos_production_pxe.vmlinuz
    ln -sf $CACHE_DIR/coreos_production_pxe_image.cpio.gz $SRV_DIR/coreos_production_pxe_image.cpio.gz
}

cache_check() {
    if [[ "$CACHE_IMAGES" == "True" ]]; then
        if [[ ! -d "$CACHE_DIR" ]]; then
            get_images
            ammend_image
        else
            echo "Using cached files for \"$RELEASE\" release." | tee -a $ERR_LOG
        fi
    elif [ "$REFRESH_IMAGES" = "False" ]; then
        echo "Using original files for \"$RELEASE\" release." | tee -a $ERR_LOG
    else
        echo "Refresh files is set." | tee -a $ERR_LOG
        get_images
        ammend_image
    fi
}

dns_check() {
    if [[ "$DNS_CHECK" == "True" ]]; then
        echo -n "Waiting for DNS to come online..." | tee -a $ERR_LOG
        while ! $(host ubuntu.com 2>&1 > /dev/null); do
            sleep 1s
        done
        echo "done" | tee -a $ERR_LOG
    fi
}

ammend_image() {
    ex() {
        if [[ -f $1 ]]; then
            case $1 in
                *.tar.bz2) tar -C $2 -xvjf $1;;
                *.tar.gz) tar -C $2 -xvzf $1;;
                *.tar.xz) tar -C $2 -xvJf $1;;
                *.tar.lzma) tar --lzma xvf $1;;
                *.tar) tar -C $2 -xvf $1;;
                *.tbz2) tar -C $2 -xvjf $1;;
                *.tgz) tar -C $2 -xvzf $1;;
                *) echo "'$1' cannot be extracted via >ex<";;
            esac
        else
            echo "'$1' is not a valid file"
        fi
    }

    merge() {
        echo "Ammending $RELEASE image..." | tee -a $ERR_LOG
        mkdir -p /tmp/ammend
        cd /tmp/ammend
        ex "$AMMEND_IMAGE" /tmp/ammend
        gzip -d $CACHE_DIR/coreos_production_pxe_image.cpio.gz
        find . | cpio -o -A -H newc -O $CACHE_DIR/coreos_production_pxe_image.cpio
        gzip $CACHE_DIR/coreos_production_pxe_image.cpio
        rm -rf /tmp/ammend
    }

    if [ ! "$AMMEND_IMAGE" = '' ]; then
        merge
    fi
}

dns_check

if [ ! -e /tmp/pxe_first_run ]; then
    touch /tmp/pxe_first_run
    prep_dirs
    get_signing_key
    cache_check
elif [ "$REFRESH_IMAGES" = "True" ]; then
    restart_message
    echo "Refresh files is set." | tee -a $ERR_LOG
    get_images
    ammend_image
else
    restart_message
    cache_check
fi

select_image
apply_permissions
echo Starting DHCP+TFTP server... | tee -a $ERR_LOG
exec dnsmasq \
    --conf-file=$CONF_FILE \
    --no-daemon
