#!/bin/bash -eux

#############
# Environment

if [ $(uname -m) = "x86_64" ] ; then
  arch="x86_64"
else
  arch="armv7hf"
fi

smb_share="//192.168.4.2/Public Share/Sito Ervisa"
root_mount_point="$( dirname $0 )"


#############
# Preparation

if ! which hugo ; then
  apt-get update
  apt install -y hugo
fi

mkdir -p assets content resources

mount -t cifs "$smb_share" ${root_mount_point}/assets/ -o guest,uid=1000,gid=1000

./from_assets_to_content.sh


#######
# Build

rm -rf "$( dirname $0 )/public/"
mkdir "$( dirname $0 )/public/"
hugo -D

docker build -t fabrizio2210/ervisa-album:${arch} -f docker/x86_64/Dockerfile-frontend .

##########
# Cleaning

umount ${root_mount_point}/assets/
