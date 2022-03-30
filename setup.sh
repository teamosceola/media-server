#!/bin/bash

# Elevate to root privileges if not already
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

[[ -f .env ]] && source .env

# Ensure Base Directories exist
mkdir -p ${CONFIGS_BASE_DIR}
mkdir -p ${TV_MEDIA_DIR}
mkdir -p ${MOVIE_MEDIA_DIR}
mkdir -p ${DOWNLOADS}
mkdir -p ${INCOMPLETE_DOWNLOADS}
mkdir -p ${DDCLIENT_CONF_DIR}
mkdir -p ${BACKUPS_DIR}

if [[ ${USE_S3_MEDIA} == "true" ]]
then
  apt update && apt install s3fs -y
  echo ${S3_ACCESS_KEY}:${S3_SECRET_KEY} > /etc/passwd-s3fs
  chmod 600 /etc/passwd-s3fs
  grep "${MEDIA_BASE_DIR}" /etc/fstab
  if [[ $? -ne "0" ]] ; then
    echo "${S3_BUCKET_NAME} ${MEDIA_BASE_DIR} fuse.s3fs _netdev,allow_other,use_path_request_style,url=https://${S3_URI}/ 0 0"
  fi
  mkdir -p ${MEDIA_BASE_DIR}
  mount -a
fi

# Create ddclient.conf config file
cat << EOF > ${DDCLIENT_CONF_DIR}/ddclient.conf && chown ${USERNAME}:${GROUPNAME} ${DDCLIENT_CONF_DIR}/ddclient.conf && chmod 640 ${DDCLIENT_CONF_DIR}/ddclient.conf
daemon=300
syslog=yes
pid=/var/run/ddclient/ddclient.pid
ssl=yes
use=web, web=dynamicdns.park-your-domain.com/getip
protocol=namecheap, \\
server=dynamicdns.park-your-domain.com,	\\
login=${DOMAIN_NAME}, \\
password=${NC_DDNS_PASS} \\
@.${DOMAIN_NAME},jellyfin.${DOMAIN_NAME},radarr.${DOMAIN_NAME},sonarr.${DOMAIN_NAME},code-server.${DOMAIN_NAME},sab.${DOMAIN_NAME},auth.${DOMAIN_NAME},overseerr.${DOMAIN_NAME},backups.${DOMAIN_NAME},tdarr.${DOMAIN_NAME},netdata.${DOMAIN_NAME}
EOF

# Create acme.json file for letsencrypt
mkdir -p ${CONFIGS_BASE_DIR}/letsencrypt
touch ${CONFIGS_BASE_DIR}/letsencrypt/acme.json
chmod 600 ${CONFIGS_BASE_DIR}/letsencrypt/acme.json
chown ${USERNAME}:${GROUPNAME} ${CONFIGS_BASE_DIR}/letsencrypt/acme.json

# Create redis directorie and set permissions
mkdir -p ${CONFIGS_BASE_DIR}/redis
chmod -R 777 ${CONFIGS_BASE_DIR}/redis

exit 0
