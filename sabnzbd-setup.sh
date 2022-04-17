#!/bin/bash
source .env
sed -r -i "s/(^host_whitelist = .*,).*$/\1sab.${DOMAIN_NAME}/g" ${CONFIGS_BASE_DIR}/sabnzbd/sabnzbd.ini
sed -r -i 's/^local_ranges = .*$/local_ranges = 10., 172., 192., 127./g' ${CONFIGS_BASE_DIR}/sabnzbd/sabnzbd.ini
docker-compose restart sabnzbd