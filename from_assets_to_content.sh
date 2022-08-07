#!/bin/bash -x

root_mount_point="$( dirname $0 )"

[ ! -d ${root_mount_point}/assets ] && echo "assets directory not found" && exit 1
[ ! -d ${root_mount_point}/content ] && echo "content directory not found" && exit 1
temp_dir="$(mktemp -d)"
mv ${root_mount_point}/content $temp_dir/
mkdir ${root_mount_point}/content

mount -t cifs "$smb_share" ${root_mount_point}/assets/ -o guest,uid=1000,gid=1000
cp ${root_mount_point}/assets/_index.md ${root_mount_point}/content/
(
    IFS=$'\n'
    path_orders=''
    for path in $(find ${root_mount_point}/assets/ -type d | cut -d / -f3-) ; do
        metadata="assets/${path}/metadata.txt"
        order="$(grep ^order: $metadata | tr -d '"' | sed 's/^ *//g' | cut -d : -f2-)"
        [ -z "$order" ] && order=0
        path_orders="$path_orders"$'\n'"$order":::"$path"
    done
    mapfile -d '\n' sorted_paths < <(echo "$path_orders" | sort -n -t: -k1 | awk -F::: '{print $2}')

    set +x
    echo "Sorted paths:"
    for path in ${sorted_paths[@]} ; do
        echo "$path"
    done
    set -x

    for path in ${sorted_paths[@]} ; do
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

