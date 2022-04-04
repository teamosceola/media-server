#!/bin/bash

if [[ ! -f .env ]]
then
    touch .env
    chmod 600 .env
fi

[[ -f .env ]] && source .env

function add_var_to_env_file {
    KEY=$1
    VALUE=$2
    if [[ $(egrep '^'${KEY}'=.*$' .env > /dev/null 2>&1 ; echo $?) == 0 ]]
    then
        # update
        ESCAPED_VALUE=$(printf '%s\n' "${VALUE}" | sed -e 's/[\/&]/\\&/g')
        sed -i -r "s/^${KEY}=.*$/${KEY}=${ESCAPED_VALUE}/g" .env
    else
        # append
        echo "$1=$2" >> .env
    fi
}

function update_env_file {
    add_var_to_env_file CONFIGS_BASE_DIR ${CONFIGS_BASE_DIR}
    add_var_to_env_file MEDIA_BASE_DIR ${MEDIA_BASE_DIR}
    add_var_to_env_file TV_MEDIA_DIR ${TV_MEDIA_DIR}
    add_var_to_env_file MOVIE_MEDIA_DIR ${MOVIE_MEDIA_DIR}
    add_var_to_env_file DOWNLOADS ${DOWNLOADS}
    add_var_to_env_file INCOMPLETE_DOWNLOADS ${INCOMPLETE_DOWNLOADS}
    add_var_to_env_file TDARR_TRANSCODE_CACHE ${TDARR_TRANSCODE_CACHE}
    add_var_to_env_file BACKUPS_DIR ${BACKUPS_DIR}
    add_var_to_env_file USE_S3_MEDIA ${USE_S3_MEDIA}
    add_var_to_env_file S3_ACCESS_KEY ${S3_ACCESS_KEY}
    add_var_to_env_file S3_SECRET_KEY ${S3_SECRET_KEY}
    add_var_to_env_file S3_REGION ${S3_REGION}
    add_var_to_env_file S3_URI ${S3_URI}
    add_var_to_env_file S3_BUCKET_NAME ${S3_BUCKET_NAME}
    add_var_to_env_file TZ ${TZ}
    add_var_to_env_file DDCLIENT_CONF_DIR ${DDCLIENT_CONF_DIR}
    add_var_to_env_file USERNAME ${USERNAME}
    add_var_to_env_file GROUPNAME ${GROUPNAME}
    add_var_to_env_file USERID ${USERID}
    add_var_to_env_file GROUPID ${GROUPID}
    add_var_to_env_file DOMAIN_NAME ${DOMAIN_NAME}
    add_var_to_env_file NC_DDNS_PASS ${NC_DDNS_PASS}
    add_var_to_env_file EMAIL ${EMAIL}
    add_var_to_env_file KEYCLOAK_ADMIN_PASSWORD ${KEYCLOAK_ADMIN_PASSWORD}
    add_var_to_env_file POSTGRES_KEYCLOAK_ADMIN_PASSWORD ${POSTGRES_KEYCLOAK_ADMIN_PASSWORD}
    add_var_to_env_file KEYCLOAK_RADARR_SECRET ${KEYCLOAK_RADARR_SECRET}
    add_var_to_env_file KEYCLOAK_SONARR_SECRET ${KEYCLOAK_SONARR_SECRET}
    add_var_to_env_file KEYCLOAK_TDARR_SECRET ${KEYCLOAK_TDARR_SECRET}
    add_var_to_env_file KEYCLOAK_SABNZBD_SECRET ${KEYCLOAK_SABNZBD_SECRET}
    add_var_to_env_file KEYCLOAK_OVERSEERR_SECRET ${KEYCLOAK_OVERSEERR_SECRET}
    add_var_to_env_file KEYCLOAK_CODE_SERVER_SECRET ${KEYCLOAK_CODE_SERVER_SECRET}
    add_var_to_env_file KEYCLOAK_DUPLICATI_SECRET ${KEYCLOAK_DUPLICATI_SECRET}
    add_var_to_env_file KEYCLOAK_JELLYFIN_SECRET ${KEYCLOAK_JELLYFIN_SECRET}
    add_var_to_env_file KEYCLOAK_NETDATA_SECRET ${KEYCLOAK_NETDATA_SECRET}
    add_var_to_env_file KEYCLOAK_MASTER_SECRET ${KEYCLOAK_MASTER_SECRET}
    add_var_to_env_file KEYCLOAK_USER_SECRET ${KEYCLOAK_USER_SECRET}
    add_var_to_env_file WIREGUARD_INTERNAL_SUBNET ${WIREGUARD_INTERNAL_SUBNET}
    add_var_to_env_file APPS_NET_SUBNET ${APPS_NET_SUBNET}
}

### Directory locations ###
# App configs (Recommend using local NVMe or SSD storage)
[[ -z $CONFIGS_BASE_DIR ]] && CONFIGS_BASE_DIR=/data/configs
# Media (Mass Bulk Storage, could be network attached or local)
[[ -z $MEDIA_BASE_DIR ]] && MEDIA_BASE_DIR=/data/media
[[ -z $TV_MEDIA_DIR ]] && TV_MEDIA_DIR=${MEDIA_BASE_DIR}/tv
[[ -z $MOVIE_MEDIA_DIR ]] && MOVIE_MEDIA_DIR=${MEDIA_BASE_DIR}/movies
# Downloads (Recommend using local direct attached storage)
[[ -z $DOWNLOADS ]] && DOWNLOADS=/data/downloads/complete
[[ -z $INCOMPLETE_DOWNLOADS ]] && INCOMPLETE_DOWNLOADS=/data/downloads/incomplete
# Transcode Cache for Tdarr (Recommend using local direct attached storage)
[[ -z $TDARR_TRANSCODE_CACHE ]] && TDARR_TRANSCODE_CACHE=/data/transcode_cache
# Backups (destination for duplicati backups of App configs)
[[ -z $BACKUPS_DIR ]] && BACKUPS_DIR=/data/backups

### S3 Storage info ###
# Set USE_S3_MEDIA=true to use S3 as media storage backend (This is slow)
[[ -z $USE_S3_MEDIA ]] && USE_S3_MEDIA=false
[[ -z $S3_ACCESS_KEY ]] && S3_ACCESS_KEY=
[[ -z $S3_SECRET_KEY ]] && S3_SECRET_KEY=
[[ -z $S3_REGION ]] && S3_REGION=us-east-2
[[ -z $S3_URI ]] && S3_URI=s3.us-east-2.wasabisys.com
[[ -z $S3_BUCKET_NAME ]] && S3_BUCKET_NAME=

# Use the command 'timedatectl list-timezones' to list all available timezones
[[ -z $TZ ]] && TZ=America/Chicago

[[ -z $DDCLIENT_CONF_DIR ]] && DDCLIENT_CONF_DIR=${CONFIGS_BASE_DIR}/ddclient

# USERNAME=$(who | cut -d' ' -f1)
# GROUPNAME=$(id -ng ${USERNAME})
# USERID=$(id -u ${USERNAME})
# GROUPID=$(id -g ${USERNAME})

[[ -z $USERNAME ]] && USERNAME=root
[[ -z $GROUPNAME ]] && GROUPNAME=root
[[ -z $USERID ]] && USERID=0
[[ -z $GROUPID ]] && GROUPID=0

if [[ -z $DOMAIN_NAME ]]
then
    read -p 'Enter Domain Name: ' DOMAIN_NAME
fi
if [[ -z $NC_DDNS_PASS ]]
then
    read -p 'Enter NameCheap DDNS Password: ' NC_DDNS_PASS
fi
if [[ -z $EMAIL ]]
then
    read -p 'Enter Email Address: ' EMAIL
fi
if [[ -z $KEYCLOAK_ADMIN_PASSWORD ]]
then
    KEYCLOAK_ADMIN_PASSWORD=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())')
fi
if [[ -z $POSTGRES_KEYCLOAK_ADMIN_PASSWORD ]]
then
    POSTGRES_KEYCLOAK_ADMIN_PASSWORD=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())')
fi
if [[ -z $KEYCLOAK_RADARR_SECRET ]]
then
    KEYCLOAK_RADARR_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_SONARR_SECRET ]]
then
    KEYCLOAK_SONARR_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_TDARR_SECRET ]]
then
    KEYCLOAK_TDARR_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_SABNZBD_SECRET ]]
then
    KEYCLOAK_SABNZBD_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_OVERSEERR_SECRET ]]
then
    KEYCLOAK_OVERSEERR_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_CODE_SERVER_SECRET ]]
then
    KEYCLOAK_CODE_SERVER_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_DUPLICATI_SECRET ]]
then
    KEYCLOAK_DUPLICATI_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_JELLYFIN_SECRET ]]
then
    KEYCLOAK_JELLYFIN_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_NETDATA_SECRET ]]
then
    KEYCLOAK_NETDATA_SECRET=$(uuidgen)
fi
if [[ -z $KEYCLOAK_MASTER_SECRET ]]
then
    KEYCLOAK_MASTER_SECRET=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())')
fi
if [[ -z $KEYCLOAK_USER_SECRET ]]
then
    KEYCLOAK_USER_SECRET=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())')
fi
if [[ -z $WIREGUARD_INTERNAL_SUBNET ]]
then
    WIREGUARD_INTERNAL_SUBNET=10.$(shuf -i 1-255 -n 1).$(shuf -i 1-255 -n 1).0
fi
if [[ -z $APPS_NET_SUBNET ]]
then
    APPS_NET_SUBNET=172.$(shuf -i 20-30 -n 1)
fi

# needs to be last
update_env_file

exit 0
