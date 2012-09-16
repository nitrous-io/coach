#!/bin/bash

boxId=${1}
boxName=${2}
boxerId=${3}

post_data="box[id]=${boxId}&box[boxer_id]=${boxerId}"

curl -X PUT --user aio:foobar http://127.0.0.1:5000/boxes/${boxName}/destroy -d ${post_data} 
