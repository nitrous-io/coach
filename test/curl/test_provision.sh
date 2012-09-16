#!/bin/bash

boxId=${1}
boxName=${2}

post_data="box[runtime]=ruby&box[memory]=256&box[disk_space]=4096&box[id]=${boxId}&box[name]=${boxName}"

curl -X POST --user aio:foobar http://127.0.0.1:5000/boxes -d ${post_data} 
