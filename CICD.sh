#!/bin/bash -eux

#############
# Environment

if [ $(uname -m) = "x86_64" ] ; then
  arch="x86_64"
else
  arch="armv7hf"
fi

_host="192.168.4.2"
if [ ${LOCATION} = "LONDON" ] ; then
  _host="192.168.100.2"
fi


assets_smb_share="//${_host}/Public Share/Sito Ervisa Moda"
assets_nfs_share="${_host}:/mnt/HDD/samba/Sito Ervisa Moda"
root_mount_point="$( dirname $0 )"

start_time=$(date +%s)

printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

#############
# Preparation

mkdir -p assets content
[ -d "${PROJECT_REPOSITORY}/hugo" ] || mkdir ${PROJECT_REPOSITORY}/hugo
mkdir -p ${PROJECT_REPOSITORY}/hugo/resources

ln -s ${PROJECT_REPOSITORY}/hugo/resources/ ./resources
ls -la ./resources
ls -la ./resources/
mount -t cifs "$assets_smb_share" ${root_mount_point}/assets/ -o guest,uid=1000,gid=1000
#mount "$assets_nfs_share" ${root_mount_point}/assets/ -o nolock,soft
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))


./from_assets_to_content.sh

printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
#######
# Build

rm -rf "${PROJECT_REPOSITORY}/hugo/public/"
mkdir -p "${PROJECT_REPOSITORY}/hugo/public/"
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
hugo -D --verbose --verboseLog --baseURL http://ervisa.no-ip.dynu.net/ --destination "${PROJECT_REPOSITORY}/hugo/public"
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

##########
# Cleaning

umount ${root_mount_point}/assets/
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

#####
# Run

VOLUME=$(echo $PROJECTS_VOLUME_STRING | cut -d: -f1)
INTERNAL_MOUNTPOINT=$(echo $PROJECTS_VOLUME_STRING | cut -d: -f2)
REAL_MOUNTPOINT=$(docker volume inspect $VOLUME -f "{{ .Mountpoint}}")
REAL_REPO_MOUNTPOINT=${REAL_MOUNTPOINT}/${PROJECT_REPOSITORY#$INTERNAL_MOUNTPOINT}/hugo/public

if docker service ps ervisa-www ; then
  docker service rm ervisa-www
  printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
fi
docker service create --quiet --name "ervisa-www" -l traefik.port=80 -l traefik.enable=true -l traefik.http.routers.ervisafe.rule='Host(`ervisa.no-ip.dynu.net`)' -l traefik.http.services.ervisafe-service.loadbalancer.server.port=80 --network traefik_backends --mount type=bind,src=$REAL_REPO_MOUNTPOINT,dst=/usr/share/nginx/html,readonly nginx
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

#################
# Cleaning Docker

docker container prune --force
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
docker image prune --force
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
