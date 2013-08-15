#!/bin/bash

boxId=${1}
boxName=${2}
boxerId=${3}

post_data="box[id]=${boxId}&box[boxer_id]=${boxerId}&box[data_type]=aio%3Aconfigure%3Aremove_env_variables&box[data]=%5B%22HEROKU_POSTGRES_URL%22%5D"

curl -X PUT --user aio:foobar http://127.0.0.1:5000/boxes/${boxName} -d ${post_data} 
