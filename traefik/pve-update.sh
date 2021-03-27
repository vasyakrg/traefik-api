#!/bin/bash

DOMAIN=pve.domain.ru

PEM=pveproxy-ssl.pem
KEY=pveproxy-ssl.key
DEST_PATH=/etc/pve/local

SERVICE_RESTART=pveproxy

echo "[ START ] on $(date +'%d-%m-%Y_%H-%M')"

cp certs/${DOMAIN}/cert.pem ${DEST_PATH}/${PEM}
cp certs/${DOMAIN}/privkey.pem ${DEST_PATH}/${KEY}

SERVICE_RESTART=pveproxy

systemctl restart $SERVICE_RESTART
[[ ! $? -eq 0 ]] && echo "service not restarted, restart manually"

echo "[ END ] on $(date +'%d-%m-%Y_%H-%M')"
echo ""
