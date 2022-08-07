#!/bin/bash -x

smb_share="//192.168.4.2/Public Share/Sito Ervisa"
root_mount_point="$( dirname $0 )"

[ ! -d ${root_mount_point}/assets ] && echo "assets directory not found" && exit 1
[ ! -d ${root_mount_point}/content ] && echo "content directory not found" && exit 1
temp_dir="$(mktemp -d)"
mv ${root_mount_point}/content $temp_dir/
mkdir ${root_mount_point}/content

sudo mount -t cifs "$smb_share" ${root_mount_point}/assets/ -o guest,uid=1000,gid=1000
(
    IFS=$'\n'
    for path in $(find ${root_mount_point}/assets/ -type d | cut -d / -f3-) ; do
        album="$(basename "$path")"

        base_name="${album}_"
        metadata="assets/${path}/metadata.txt"
        title="$(grep ^title: $metadata | tr -d '"' | sed 's/^ *//g' | cut -d : -f2-)"
        [ -z "$title" ] && title="$(echo ${path} | rev | cut -d / -f1 | rev)"
        description="$(grep ^description: $metadata | tr -d '"' | sed 's/^ *//g' | cut -d : -f2-)"
        subdescription="$(grep ^subdescription: $metadata | tr -d '"' | sed 's/^ *//g' | cut -d : -f2-)"
        

        ## Convert images
    #    (
    #        IFS=$'\n'
    #        i=1 ; 
    #        for _file in $(ls --quoting-style=literal -1 assets/${path}/*.jpg | grep -v "assets/${path}/${base_name}[[:digit:]]*.jpg"); do
    #            _destfile="assets/${path}/${base_name}${i}.jpg"
    #            if [ ! -f "$_destfile" ]; then
    #                convert "$_file" -resize 960x960 "$_destfile" ; 
    #            fi
    #            if [ "$_file" != "$_destfile" ]; then
    #                mv "$_file" /tmp/
    #            fi
    #            let i=$i+1 ;
    #        done
    #    )

        hugo new "${path}/_index.md"

        index="content/${path}/_index.md"

        cat << EOF > $index
---
title: "${title}"
description: "${description}"
subdescription: "${subdescription}"
date: $(date -Iseconds)
draft: false
resources:
EOF
    
       # (
       #     IFS=$'\n'
       #     for _image in $(ls --quoting-style=literal -1  "assets/${path}/*.jpg" | cut -d / -f2-); do
       #         echo "- src: \"${_image}\"" >> $index
       #     done
       # )    
        echo "---" >> $index
    
    done
)

hugo server
rm -rf "$( dirname $0 )/public/"
mkdir "$( dirname $0 )/public/"
hugo -D

sudo umount ${root_mount_point}/assets/
