#!/bin/sh

PASSWORD=$(cat /etc/redis-passwd/passwd)
HOSTNAME=$(echo ${HOSTNAME})

if [ "${HOSTNAME}" = "redis-0" ]; then  
    redis-server --requirepass "${PASSWORD}"  
else  
    redis-server --slaveof redis-0.redis 6379 --masterauth "${PASSWORD}" --requirepass "${PASSWORD}"  
fi