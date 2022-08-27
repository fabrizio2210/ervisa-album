#!/bin/bash -eux

#############
# Environment

if [ $(uname -m) = "x86_64" ] ; then
  arch="x86_64"
else
  arch="armv7hf"
fi

assets_nfs_share="192.168.4.2:/mnt/HDD/samba/Sito Ervisa"
resources_nfs_share="192.168.4.1:/mnt/HDD/docker/hugo/ervisa-album/resources/"
root_mount_point="$( dirname $0 )"


#############
# Preparation

if ! which hugo ; then
  apt-get update
  apt install -y wget nfs-common
  TEMP_DEB="$(mktemp)" &&
  wget -O "$TEMP_DEB" 'https://github.com/gohugoio/hugo/releases/download/v0.101.0/hugo_0.101.0_Linux-ARM.deb'
  dpkg -i "$TEMP_DEB"
fi

mkdir -p assets content resources

mount "$assets_nfs_share" ${root_mount_point}/assets/ -o nolock,soft
mount "$resources_nfs_share" ${root_mount_point}/resources/ -o nolock,soft,rw

./from_assets_to_content.sh


#######
# Build

rm -rf "$( dirname $0 )/public/"
mkdir "$( dirname $0 )/public/"
ls -l
ls -l themes/autophugo
ls -l assets
ls -l assets/cinema
hugo -D
ls -l "$( dirname $0 )/public/"

docker build -t fabrizio2210/ervisa-album:${arch} -f docker/x86_64/Dockerfile-frontend ./public/

##########
# Cleaning

umount ${root_mount_point}/assets/
umount ${root_mount_point}/resources/

#####
# Run

if docker inspect ervisa-www ; then
  docker rm ervisa-www
fi
docker run --rm -d --name "ervisa-www" -l traefik.port=80 -l traefik.enable=true -l traefik.http.routers.lightcicdfe.rule:='Host(`ervisa.no-ip.dynu.net`)' -l traefik.http.services.lightcicdfe-service.loadbalancer.server.port=80 --network Traefik_backends fabrizio2210/ervisa-album:${arch} 
