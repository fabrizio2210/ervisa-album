#!/bin/bash -eux

#############
# Environment

if [ $(uname -m) = "x86_64" ] ; then
  arch="x86_64"
else
  arch="armv7hf"
fi

assets_smb_share="//192.168.4.2/Public Share/Sito Ervisa"
assets_nfs_share="192.168.4.2:/mnt/HDD/samba/Sito Ervisa"
resources_nfs_share="192.168.4.1:/mnt/HDD/docker/hugo/ervisa-album/resources/"
root_mount_point="$( dirname $0 )"

start_time=$(date +%s)

################
# Login creation

if [ ! -f ~/.docker/config.json ] ; then 
  mkdir -p ~/.docker/

  if [ -z "$DOCKER_LOGIN" ] ; then
	  echo "Docker login not found in the environment, set DOCKER_LOGIN"
  else
    cat << EOF > ~/.docker/config.json
{
  "experimental": "enabled",
        "auths": {
                "https://index.docker.io/v1/": {
                        "auth": "$DOCKER_LOGIN"
                }
        },
        "HttpHeaders": {
                "User-Agent": "Docker-Client/17.12.1-ce (linux)"
        }
}
EOF
  fi
fi

printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

#############
# Preparation

mkdir -p assets content resources

mount -t cifs "$assets_smb_share" ${root_mount_point}/assets/ -o guest,uid=1000,gid=1000
#mount "$assets_nfs_share" ${root_mount_point}/assets/ -o nolock,soft
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
mount "$resources_nfs_share" ${root_mount_point}/resources/ -o nolock,soft,rw
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))


./from_assets_to_content.sh

printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
#######
# Build

rm -rf "$( dirname $0 )/public/"
mkdir "$( dirname $0 )/public/"
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
hugo -D --verbose --verboseLog --baseURL http://ervisa.no-ip.dynu.net/
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

docker build -t fabrizio2210/ervisa-album:${arch} -f docker/x86_64/Dockerfile-frontend ./public/
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
docker push fabrizio2210/ervisa-album:${arch}
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

##########
# Cleaning

umount ${root_mount_point}/assets/
umount ${root_mount_point}/resources/
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

#####
# Run

if docker service ps ervisa-www ; then
  docker service rm ervisa-www
  printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
fi
docker service create --quiet --name "ervisa-www" -l traefik.port=80 -l traefik.enable=true -l traefik.http.routers.ervisafe.rule='Host(`ervisa.no-ip.dynu.net`)' -l traefik.http.services.ervisafe-service.loadbalancer.server.port=80 --network Traefik_backends fabrizio2210/ervisa-album:${arch} 
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))

#################
# Cleaning Docker

docker container prune --force
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
docker image prune --force
printf '%(%-Mm %-S)T s\n' $(($(date +%s)-$start_time))
