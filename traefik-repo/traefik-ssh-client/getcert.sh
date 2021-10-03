#!/bin/bash

source .env

echo "[ START ] on $(date +'%d-%m-%Y_%H-%M')"

scp ${REMOTE_TRAEFIK}:${REMOTE_PATH}/${DOMAIN}/cert.pem ${DEST_PATH}/${PEM}
[ ! $? ] && exit 1
scp ${REMOTE_TRAEFIK}:${REMOTE_PATH}/${DOMAIN}/privkey.pem ${DEST_PATH}/${KEY}
[ ! $? ] && exit 1

systemctl restart $SERVICE_RESTART
[[ ! $? -eq 0 ]] && echo "service not restarted, you need restart manually"

echo "[ END ]"
echo ""
