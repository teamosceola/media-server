#!/bin/bash

# Elevate to root privileges if not already
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

#############################################################
##### Edit the following variables to match your system #####
#############################################################

### Directory locations ###
# App configs (Recommend using local NVMe or SSD storage)
CONFIGS_BASE_DIR=/data/configs
# Media (Mass Bulk Storage, could be network attached or local)
MEDIA_BASE_DIR=/data/media
TV_MEDIA_DIR=${MEDIA_BASE_DIR}/tv
MOVIE_MEDIA_DIR=${MEDIA_BASE_DIR}/movies
# Downloads (Recommend using local direct attached storage)
DOWNLOADS=/data/downloads/complete
INCOMPLETE_DOWNLOADS=/data/downloads/incomplete
# Transcode Cache for Tdarr (Recommend using local direct attached storage)
TDARR_TRANSCODE_CACHE=/data/transcode_cache
# Backups (destination for duplicati backups of App configs)
BACKUPS_DIR=/data/backups

### S3 Storage info ###
# Set USE_S3_MEDIA=true to use S3 as media storage backend (This is slow)
USE_S3_MEDIA=false
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_REGION=us-east-2
S3_URI=s3.us-east-2.wasabisys.com
S3_BUCKET_NAME=

# Use the command 'timedatectl list-timezones' to list all available timezones
TZ=America/Chicago

#############################################################
#####               Don't Change Below Here             #####
#############################################################

DDCLIENT_CONF_DIR=${CONFIGS_BASE_DIR}/ddclient

# Ensure Base Directories exist
mkdir -p ${CONFIGS_BASE_DIR}
mkdir -p ${TV_MEDIA_DIR}
mkdir -p ${MOVIE_MEDIA_DIR}
mkdir -p ${DOWNLOADS}
mkdir -p ${INCOMPLETE_DOWNLOADS}
mkdir -p ${DDCLIENT_CONF_DIR}
mkdir -p ${BACKUPS_DIR}

USERNAME=$(who | cut -d' ' -f1)
GROUPNAME=$(id -ng ${USERNAME})
USERID=$(id -u ${USERNAME})
GROUPID=$(id -g ${USERNAME})

[[ -f ${CONFIGS_BASE_DIR}/secrets ]] && source ${CONFIGS_BASE_DIR}/secrets

if [[ -z $DOMAIN_NAME ]]
then
    read -p 'Enter Domain Name: ' DOMAIN_NAME
    echo "DOMAIN_NAME=$DOMAIN_NAME" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $NC_DDNS_PASS ]]
then
    read -p 'Enter NameCheap DDNS Password: ' NC_DDNS_PASS
    echo "NC_DDNS_PASS=$NC_DDNS_PASS" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $EMAIL ]]
then
    read -p 'Enter Email Address: ' EMAIL
    echo "EMAIL=$EMAIL" >> ${CONFIGS_BASE_DIR}/secrets
fi

if [[ -z $KEYCLOAK_ADMIN_PASSWORD ]]
then
    KEYCLOAK_ADMIN_PASSWORD=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())')
    echo "KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_RADARR_SECRET ]]
then
    KEYCLOAK_RADARR_SECRET=$(uuidgen)
    echo "KEYCLOAK_RADARR_SECRET=$KEYCLOAK_RADARR_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_SONARR_SECRET ]]
then
    KEYCLOAK_SONARR_SECRET=$(uuidgen)
    echo "KEYCLOAK_SONARR_SECRET=$KEYCLOAK_SONARR_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_TDARR_SECRET ]]
then
    KEYCLOAK_TDARR_SECRET=$(uuidgen)
    echo "KEYCLOAK_TDARR_SECRET=$KEYCLOAK_TDARR_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_SABNZBD_SECRET ]]
then
    KEYCLOAK_SABNZBD_SECRET=$(uuidgen)
    echo "KEYCLOAK_SABNZBD_SECRET=$KEYCLOAK_SABNZBD_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_OMBI_SECRET ]]
then
    KEYCLOAK_OMBI_SECRET=$(uuidgen)
    echo "KEYCLOAK_OMBI_SECRET=$KEYCLOAK_OMBI_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_OVERSEERR_SECRET ]]
then
    KEYCLOAK_OVERSEERR_SECRET=$(uuidgen)
    echo "KEYCLOAK_OVERSEERR_SECRET=$KEYCLOAK_OVERSEERR_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_CODE_SERVER_SECRET ]]
then
    KEYCLOAK_CODE_SERVER_SECRET=$(uuidgen)
    echo "KEYCLOAK_CODE_SERVER_SECRET=$KEYCLOAK_CODE_SERVER_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_DUPLICATI_SECRET ]]
then
    KEYCLOAK_DUPLICATI_SECRET=$(uuidgen)
    echo "KEYCLOAK_DUPLICATI_SECRET=$KEYCLOAK_DUPLICATI_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_JELLYFIN_SECRET ]]
then
    KEYCLOAK_JELLYFIN_SECRET=$(uuidgen)
    echo "KEYCLOAK_JELLYFIN_SECRET=$KEYCLOAK_JELLYFIN_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_NETDATA_SECRET ]]
then
    KEYCLOAK_NETDATA_SECRET=$(uuidgen)
    echo "KEYCLOAK_NETDATA_SECRET=$KEYCLOAK_NETDATA_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_MASTER_SECRET ]]
then
    KEYCLOAK_MASTER_SECRET=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())')
    echo "KEYCLOAK_MASTER_SECRET=$KEYCLOAK_MASTER_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $KEYCLOAK_USER_SECRET ]]
then
    KEYCLOAK_USER_SECRET=$(python3 -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())')
    echo "KEYCLOAK_USER_SECRET=$KEYCLOAK_USER_SECRET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $WIREGUARD_INTERNAL_SUBNET ]]
then
    WIREGUARD_INTERNAL_SUBNET=10.$(shuf -i 1-255 -n 1).$(shuf -i 1-255 -n 1).0
    echo "WIREGUARD_INTERNAL_SUBNET=$WIREGUARD_INTERNAL_SUBNET" >> ${CONFIGS_BASE_DIR}/secrets
fi
if [[ -z $APPS_NET_SUBNET ]]
then
    APPS_NET_SUBNET=172.$(shuf -i 20-30 -n 1)
    echo "APPS_NET_SUBNET=$APPS_NET_SUBNET" >> ${CONFIGS_BASE_DIR}/secrets
fi


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

# Set directory ownership and permissions
chmod 600 ${CONFIGS_BASE_DIR}/secrets

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
@.${DOMAIN_NAME},jellyfin.${DOMAIN_NAME},radarr.${DOMAIN_NAME},sonarr.${DOMAIN_NAME},code-server.${DOMAIN_NAME},sab.${DOMAIN_NAME},auth.${DOMAIN_NAME},ombi.${DOMAIN_NAME},overseerr.${DOMAIN_NAME},backups.${DOMAIN_NAME},tdarr.${DOMAIN_NAME},netdata.${DOMAIN_NAME}
EOF

# Create acme.json file for letsencrypt
mkdir -p ${CONFIGS_BASE_DIR}/letsencrypt
touch ${CONFIGS_BASE_DIR}/letsencrypt/acme.json
chmod 600 ${CONFIGS_BASE_DIR}/letsencrypt/acme.json
chown ${USERNAME}:${GROUPNAME} ${CONFIGS_BASE_DIR}/letsencrypt/acme.json

# Create redis directorie and set permissions
mkdir -p ${CONFIGS_BASE_DIR}/redis
chmod -R 777 ${CONFIGS_BASE_DIR}/redis

cat << EOF > ${CONFIGS_BASE_DIR}/docker-compose.yml && chown ${USERNAME}:${GROUPNAME} ${CONFIGS_BASE_DIR}/docker-compose.yml && chmod 640 ${CONFIGS_BASE_DIR}/docker-compose.yml
---
version: "3"
networks:
  apps_net:
    driver: bridge
    name: apps_net
    ipam:
      driver: default
      config:
        - subnet: ${APPS_NET_SUBNET}.0.0/16
          gateway: ${APPS_NET_SUBNET}.0.1
  apps_protected_net:
    name: apps_protected_net
  keycloak_db:
    name: keycloak_db
    internal: true
  redis:
    name: redis
    internal: true
volumes:
  netdataconfig:
  netdatalib:
  netdatacache:
services:
  sonarr:
    image: ghcr.io/linuxserver/sonarr
    labels:
      - traefik.enable=false
    container_name: sonarr
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
    volumes:
      - ${CONFIGS_BASE_DIR}/sonarr:/config
      - ${TV_MEDIA_DIR}:/tv
      - ${DOWNLOADS}/tv:/downloads  
    networks:
      - apps_protected_net
    restart: unless-stopped
  sonarr-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: sonarr-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.sonarr_svc.loadbalancer.server.port=4180
      - traefik.http.services.sonarr_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.sonarr.service=sonarr_svc
      - traefik.http.routers.sonarr.rule=Host(\`sonarr.${DOMAIN_NAME}\`)
      - traefik.http.routers.sonarr.entrypoints=websecure
      - traefik.http.routers.sonarr.tls=true
      - traefik.http.routers.sonarr.tls.certresolver=le
      - traefik.http.routers.sonarr-http.entrypoints=web
      - traefik.http.routers.sonarr-http.rule=Host(\`sonarr.${DOMAIN_NAME}\`)
      - traefik.http.routers.sonarr-http.middlewares=sonarr-https-redirect
      - traefik.http.middlewares.sonarr-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.sonarr-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_MASTER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_master
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://sonarr:8989
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=sonarr
      - --client-secret=${KEYCLOAK_SONARR_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - sonarr
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  radarr:
    image: ghcr.io/linuxserver/radarr
    labels:
      - traefik.enable=false
    container_name: radarr
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
    volumes:
      - ${CONFIGS_BASE_DIR}/radarr:/config
      - ${MOVIE_MEDIA_DIR}:/movies
      - ${DOWNLOADS}/movies:/downloads
    networks:
      - apps_protected_net
    restart: unless-stopped
  radarr-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: radarr-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.radarr_svc.loadbalancer.server.port=4180
      - traefik.http.services.radarr_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.radarr.service=radarr_svc
      - traefik.http.routers.radarr.rule=Host(\`radarr.${DOMAIN_NAME}\`)
      - traefik.http.routers.radarr.entrypoints=websecure
      - traefik.http.routers.radarr.tls=true
      - traefik.http.routers.radarr.tls.certresolver=le
      - traefik.http.routers.radarr-http.entrypoints=web
      - traefik.http.routers.radarr-http.rule=Host(\`radarr.${DOMAIN_NAME}\`)
      - traefik.http.routers.radarr-http.middlewares=radarr-https-redirect
      - traefik.http.middlewares.radarr-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.radarr-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_MASTER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_master
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://radarr:7878
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=radarr
      - --client-secret=${KEYCLOAK_RADARR_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - radarr
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  tdarr:
    image: haveagitgat/tdarr:latest
    labels:
      - traefik.enable=false
    container_name: tdarr
    ports:
      - 8265:8265
      - 8266:8266
      - 8267:8267
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
      - UMASK_SET=002
      - serverIP=0.0.0.0
      - serverPort=8266
      - webUIPort=8265
    volumes:
      - ${CONFIGS_BASE_DIR}/tdarr/server:/app/server
      - ${CONFIGS_BASE_DIR}/tdarr/configs:/app/configs
      - ${CONFIGS_BASE_DIR}/tdarr/logs:/app/logs
      - ${MEDIA_BASE_DIR}:/media
      - ${TDARR_TRANSCODE_CACHE}:/temp
    networks:
      - apps_protected_net
    restart: unless-stopped
  tdarr-node:
    image: haveagitgat/tdarr_node:latest
    labels:
      - traefik.enable=false
    container_name: tdarr-node
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
      - UMASK_SET=002
      - nodeID=MainNode
      - nodeIP=tdarr-node
      - nodePort=8267
      - serverIP=tdarr
      - serverPort=8266
    volumes:
      - ${CONFIGS_BASE_DIR}/tdarr/server:/app/server
      - ${CONFIGS_BASE_DIR}/tdarr/configs:/app/configs
      - ${CONFIGS_BASE_DIR}/tdarr/logs:/app/logs
      - ${MEDIA_BASE_DIR}:/media
      - ${TDARR_TRANSCODE_CACHE}:/temp
    networks:
      - apps_protected_net
    restart: unless-stopped
  tdarr-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: tdarr-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.tdarr_svc.loadbalancer.server.port=4180
      - traefik.http.services.tdarr_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.tdarr.service=tdarr_svc
      - traefik.http.routers.tdarr.rule=Host(\`tdarr.${DOMAIN_NAME}\`)
      - traefik.http.routers.tdarr.entrypoints=websecure
      - traefik.http.routers.tdarr.tls=true
      - traefik.http.routers.tdarr.tls.certresolver=le
      - traefik.http.routers.tdarr-http.entrypoints=web
      - traefik.http.routers.tdarr-http.rule=Host(\`tdarr.${DOMAIN_NAME}\`)
      - traefik.http.routers.tdarr-http.middlewares=tdarr-https-redirect
      - traefik.http.middlewares.tdarr-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.tdarr-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_MASTER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_master
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://tdarr:8265
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=tdarr
      - --client-secret=${KEYCLOAK_TDARR_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - tdarr
      - tdarr-node
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  ombi:
    image: ghcr.io/linuxserver/ombi
    labels:
      - traefik.enable=false
    container_name: ombi
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
      - BASE_URL=/
    volumes:
      - ${CONFIGS_BASE_DIR}/ombi:/config
    networks:
      - apps_protected_net
    restart: unless-stopped
  ombi-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: ombi-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.ombi_svc.loadbalancer.server.port=4180
      - traefik.http.services.ombi_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.ombi.service=ombi_svc
      - traefik.http.routers.ombi.rule=Host(\`ombi.${DOMAIN_NAME}\`)
      - traefik.http.routers.ombi.entrypoints=websecure
      - traefik.http.routers.ombi.tls=true
      - traefik.http.routers.ombi.tls.certresolver=le
      - traefik.http.routers.ombi-http.entrypoints=web
      - traefik.http.routers.ombi-http.rule=Host(\`ombi.${DOMAIN_NAME}\`)
      - traefik.http.routers.ombi-http.middlewares=ombi-https-redirect
      - traefik.http.middlewares.ombi-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.ombi-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_USER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_user
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/user
      - --upstream=http://ombi:3579
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=ombi
      - --client-secret=${KEYCLOAK_OMBI_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - ombi
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  sabnzbd:
    image: ghcr.io/linuxserver/sabnzbd
    labels:
      - traefik.enable=false
    container_name: sabnzbd
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
    volumes:
      - ${CONFIGS_BASE_DIR}/sabnzbd:/config
      - ${DOWNLOADS}:/downloads
      - ${INCOMPLETE_DOWNLOADS}:/incomplete-downloads
    networks:
      - apps_protected_net
    restart: unless-stopped
  sabnzbd-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: sabnzbd-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.sabnzbd_svc.loadbalancer.server.port=4180
      - traefik.http.services.sabnzbd_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.sabnzbd.service=sabnzbd_svc
      - traefik.http.routers.sabnzbd.rule=Host(\`sab.${DOMAIN_NAME}\`)
      - traefik.http.routers.sabnzbd.entrypoints=websecure
      - traefik.http.routers.sabnzbd.tls=true
      - traefik.http.routers.sabnzbd.tls.certresolver=le
      - traefik.http.routers.sabnzbd-http.entrypoints=web
      - traefik.http.routers.sabnzbd-http.rule=Host(\`sab.${DOMAIN_NAME}\`)
      - traefik.http.routers.sabnzbd-http.middlewares=sabnzbd-https-redirect
      - traefik.http.middlewares.sabnzbd-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.sabnzbd-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_MASTER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_master
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://sabnzbd:8080
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=sabnzbd
      - --client-secret=${KEYCLOAK_SABNZBD_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - sabnzbd
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  plex:
    image: ghcr.io/linuxserver/plex
    container_name: plex
    labels:
      - traefik.enable=false
    network_mode: host
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - VERSION=docker
    volumes:
      - ${CONFIGS_BASE_DIR}/plex:/config
      - ${TV_MEDIA_DIR}:/tv
      - ${MOVIE_MEDIA_DIR}:/movies
    # devices:
    #   - /dev/dri/renderD128:/dev/dri/renderD128
    #   - /dev/dri/card0:/dev/dri/card0
    restart: unless-stopped
  jellyfin:
    image: ghcr.io/linuxserver/jellyfin
    labels:
      - traefik.enable=false
    container_name: jellyfin
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
    volumes:
      - ${CONFIGS_BASE_DIR}/jellyfin:/config
      - ${TV_MEDIA_DIR}:/data/tvshows
      - ${MOVIE_MEDIA_DIR}:/data/movies
    networks:
      - apps_protected_net
    # devices:
    #   - /dev/dri/renderD128:/dev/dri/renderD128
    #   - /dev/dri/card0:/dev/dri/card0
    restart: unless-stopped
  jellyfin-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: jellyfin-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.jellyfin_svc.loadbalancer.server.port=4180
      - traefik.http.services.jellyfin_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.jellyfin.service=jellyfin_svc
      - traefik.http.routers.jellyfin.rule=Host(\`jellyfin.${DOMAIN_NAME}\`)
      - traefik.http.routers.jellyfin.entrypoints=websecure
      - traefik.http.routers.jellyfin.tls=true
      - traefik.http.routers.jellyfin.tls.certresolver=le
      - traefik.http.routers.jellyfin-http.entrypoints=web
      - traefik.http.routers.jellyfin-http.rule=Host(\`jellyfin.${DOMAIN_NAME}\`)
      - traefik.http.routers.jellyfin-http.middlewares=jellyfin-https-redirect
      - traefik.http.middlewares.jellyfin-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.jellyfin-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_USER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_user
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/user
      - --upstream=http://jellyfin:8096
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=jellyfin
      - --client-secret=${KEYCLOAK_JELLYFIN_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - jellyfin
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  code-server:
    image: ghcr.io/linuxserver/code-server
    labels:
      - traefik.enable=false
    container_name: code-server
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
    volumes:
      - ${CONFIGS_BASE_DIR}/code-server:/config
      - /data:/data
    networks:
      - apps_protected_net
    restart: unless-stopped
  code-server-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: code-server-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.code-server_svc.loadbalancer.server.port=4180
      - traefik.http.services.code-server_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.code-server.service=code-server_svc
      - traefik.http.routers.code-server.rule=Host(\`code-server.${DOMAIN_NAME}\`)
      - traefik.http.routers.code-server.entrypoints=websecure
      - traefik.http.routers.code-server.tls=true
      - traefik.http.routers.code-server.tls.certresolver=le
      - traefik.http.routers.code-server-http.entrypoints=web
      - traefik.http.routers.code-server-http.rule=Host(\`code-server.${DOMAIN_NAME}\`)
      - traefik.http.routers.code-server-http.middlewares=code-server-https-redirect
      - traefik.http.middlewares.code-server-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.code-server-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_MASTER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_master
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://code-server:8443
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=code-server
      - --client-secret=${KEYCLOAK_CODE_SERVER_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - code-server
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  overseerr:
    image: sctx/overseerr:latest
    container_name: overseerr
    labels:
      - traefik.enable=false
    environment:
      - LOG_LEVEL=info
      - TZ=${TZ}
    networks:
      - apps_protected_net
    volumes:
      - ${CONFIGS_BASE_DIR}/overseerr:/app/config
    restart: unless-stopped
  overseerr-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: overseerr-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.overseerr_svc.loadbalancer.server.port=4180
      - traefik.http.services.overseerr_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.overseerr.service=overseerr_svc
      - traefik.http.routers.overseerr.rule=Host(\`overseerr.${DOMAIN_NAME}\`)
      - traefik.http.routers.overseerr.entrypoints=websecure
      - traefik.http.routers.overseerr.tls=true
      - traefik.http.routers.overseerr.tls.certresolver=le
      - traefik.http.routers.overseerr-http.entrypoints=web
      - traefik.http.routers.overseerr-http.rule=Host(\`overseerr.${DOMAIN_NAME}\`)
      - traefik.http.routers.overseerr-http.middlewares=overseerr-https-redirect
      - traefik.http.middlewares.overseerr-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.overseerr-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_USER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_user
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/user
      - --upstream=http://overseerr:5055
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=overseerr
      - --client-secret=${KEYCLOAK_OVERSEERR_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - overseerr
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  duplicati:
    image: ghcr.io/linuxserver/duplicati
    container_name: duplicati
    labels:
      - traefik.enable=false
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
      # - CLI_ARGS= #optional
    volumes:
      - ${CONFIGS_BASE_DIR}/duplicati:/config
      - ${BACKUPS_DIR}:/backups
      - ${CONFIGS_BASE_DIR}:/source
    networks:
      - apps_protected_net
    restart: unless-stopped
  duplicati-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: duplicati-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.duplicati_svc.loadbalancer.server.port=4180
      - traefik.http.services.duplicati_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.duplicati.service=duplicati_svc
      - traefik.http.routers.duplicati.rule=Host(\`backups.${DOMAIN_NAME}\`)
      - traefik.http.routers.duplicati.entrypoints=websecure
      - traefik.http.routers.duplicati.tls=true
      - traefik.http.routers.duplicati.tls.certresolver=le
      - traefik.http.routers.duplicati-http.entrypoints=web
      - traefik.http.routers.duplicati-http.rule=Host(\`backups.${DOMAIN_NAME}\`)
      - traefik.http.routers.duplicati-http.middlewares=duplicati-https-redirect
      - traefik.http.middlewares.duplicati-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.duplicati-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_USER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_user
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://duplicati:8200
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=duplicati
      - --client-secret=${KEYCLOAK_DUPLICATI_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - duplicati
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  netdata:
    image: netdata/netdata:stable
    container_name: netdata
    labels:
      - traefik.enable=false
    cap_add:
      - SYS_PTRACE
    volumes:
      - netdataconfig:/etc/netdata
      - netdatalib:/var/lib/netdata
      - netdatacache:/var/cache/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - DOCKER_USR=root
    ports:
      - 19999:19999
    security_opt:
      - apparmor:unconfined
    networks:
      - apps_protected_net
    restart: unless-stopped
  netdata-auth-proxy:
    image: quay.io/pusher/oauth2_proxy:latest
    container_name: netdata-auth-proxy
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.netdata_svc.loadbalancer.server.port=4180
      - traefik.http.services.netdata_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.netdata.service=netdata_svc
      - traefik.http.routers.netdata.rule=Host(\`netdata.${DOMAIN_NAME}\`)
      - traefik.http.routers.netdata.entrypoints=websecure
      - traefik.http.routers.netdata.tls=true
      - traefik.http.routers.netdata.tls.certresolver=le
      - traefik.http.routers.netdata-http.entrypoints=web
      - traefik.http.routers.netdata-http.rule=Host(\`netdata.${DOMAIN_NAME}\`)
      - traefik.http.routers.netdata-http.middlewares=netdata-https-redirect
      - traefik.http.middlewares.netdata-https-redirect.redirectscheme.scheme=https
      - traefik.http.middlewares.netdata-https-redirect.redirectscheme.permanent=true
    command:
      - --provider=oidc
      - --cookie-secret=${KEYCLOAK_USER_SECRET}
      - --cookie-secure=true
      - --cookie-domain=.${DOMAIN_NAME}
      - --cookie-name=_oauth2_proxy_user
      - --cookie-samesite=lax
      - --provider-display-name="Keycloak OIDC"
      - --oidc-issuer-url=https://auth.${DOMAIN_NAME}/auth/realms/master
      - --upstream=http://netdata:19999
      - --skip-provider-button=true
      - --reverse-proxy=false
      - --pass-basic-auth=false
      - --pass-user-headers=false
      - --set-xauthrequest=false
      - --set-authorization-header=false
      - --set-basic-auth=false
      - --client-id=netdata
      - --client-secret=${KEYCLOAK_NETDATA_SECRET}
      - --http-address=0.0.0.0:4180
      - --email-domain=*
      - --ssl-insecure-skip-verify=true
      - --ssl-upstream-insecure-skip-verify=true
      - --insecure-oidc-allow-unverified-email=true
      - --insecure-oidc-skip-issuer-verification=true
      - --session-store-type=redis
      - --redis-connection-url=redis://redis
      - --trusted-ip=${APPS_NET_SUBNET}.0.1
    networks:
      - apps_net
      - apps_protected_net
      - redis
    depends_on:
      - netdata
      - redis
      - keycloak
      - reverse-proxy
    restart: unless-stopped
  postgres:
    image: postgres
    labels:
      - traefik.enable=false
    container_name: postgres-keycloak
    volumes:
      - ${CONFIGS_BASE_DIR}/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: password
    networks:
      - keycloak_db
    restart: unless-stopped
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    labels:
      - traefik.enable=true
      - traefik.docker.network=apps_net
      - traefik.http.services.keycloak_svc.loadbalancer.server.port=8080
      - traefik.http.services.keycloak_svc.loadbalancer.server.scheme=http
      - traefik.http.routers.keycloak.service=keycloak_svc
      - traefik.http.routers.keycloak.rule=Host(\`auth.${DOMAIN_NAME}\`)
      - traefik.http.routers.keycloak.entrypoints=websecure
      - traefik.http.routers.keycloak.tls=true
      - traefik.http.routers.keycloak.tls.certresolver=le
      - traefik.http.routers.keycloak-http.entrypoints=web
      - traefik.http.routers.keycloak-http.rule=Host(\`auth.${DOMAIN_NAME}\`)
      - traefik.http.routers.keycloak-http.service=keycloak_svc
      # - traefik.http.routers.keycloak-http.middlewares=keycloak-https-redirect
      # - traefik.http.middlewares.keycloak-https-redirect.redirectscheme.scheme=https
      # - traefik.http.middlewares.keycloak-https-redirect.redirectscheme.permanent=true
    container_name: keycloak
    environment:
      DB_VENDOR: POSTGRES
      DB_ADDR: postgres
      DB_DATABASE: keycloak
      DB_USER: keycloak
      DB_SCHEMA: public
      DB_PASSWORD: password
      KEYCLOAK_USER: admin
      KEYCLOAK_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
      KEYCLOAK_FRONTEND_URL: "https://auth.${DOMAIN_NAME}/auth"
    networks:
      - apps_net
      - keycloak_db
    depends_on:
      - postgres
      - reverse-proxy
    restart: unless-stopped
  ddclient:
    image: ghcr.io/linuxserver/ddclient
    labels:
      - traefik.enable=false
    container_name: ddclient
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
    volumes:
      - ${DDCLIENT_CONF_DIR}:/config
    networks:
      - apps_net
    restart: unless-stopped
  redis:
    image: 'bitnami/redis:latest'
    container_name: redis
    labels:
      - traefik.enable=false
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    volumes:
      - ${CONFIGS_BASE_DIR}/redis:/bitnami/redis/data
    networks:
      - redis
    restart: unless-stopped
  wireguard:
    image: ghcr.io/linuxserver/wireguard
    container_name: wireguard
    labels:
      - traefik.enable=false
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=${USERID}
      - PGID=${GROUPID}
      - TZ=${TZ}
      - SERVERURL=${DOMAIN_NAME}
      - SERVERPORT=51820
      - PEERS=10
      - PEERDNS=auto
      - INTERNAL_SUBNET=${WIREGUARD_INTERNAL_SUBNET}
      - ALLOWEDIPS=0.0.0.0/0
    volumes:
      - ${CONFIGS_BASE_DIR}/wireguard:/config
      - /lib/modules:/lib/modules
    ports:
      - 51820:51820/udp
    networks:
      - apps_net
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
  reverse-proxy:
    image: traefik:v2.4
    container_name: reverse-proxy
    command: >
      --api.insecure=true
      --providers.docker
      --entryPoints.web.address=:80
      --entryPoints.websecure.address=:443
      --certificatesresolvers.le.acme.httpchallenge=true
      --certificatesresolvers.le.acme.httpchallenge.entrypoint=web
      --certificatesresolvers.le.acme.email=${EMAIL}
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    networks:
      - apps_net
    volumes:
      - ${CONFIGS_BASE_DIR}/letsencrypt/acme.json:/acme.json
      # So that Traefik can listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - ddclient
    restart: unless-stopped
EOF

cat << EOF > ${CONFIGS_BASE_DIR}/keycloak-setup.sh && chown ${USERNAME}:${GROUPNAME} ${CONFIGS_BASE_DIR}/keycloak-setup.sh && chmod 700 ${CONFIGS_BASE_DIR}/keycloak-setup.sh
#!/bin/bash
until [[ \$(docker logs keycloak 2> /dev/null | grep 'Admin console listening on http://127.0.0.1:9990' > /dev/null ; echo \$?) -eq "0" ]]
do
        echo "Waiting for Keycloak to finish starting"
        sleep 5
done
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080/auth --realm master --user admin --password '${KEYCLOAK_ADMIN_PASSWORD}'
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update realms/master -s enabled=true -s bruteForceProtected=true
ID=\$(docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh get users -c -r master -q username=admin --fields id --format csv --noquotes)
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update users/\${ID} -s 'email=admin@${DOMAIN_NAME}'
ID=\$(docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh get clients -r master -q clientId=account-console --fields id --format csv --noquotes)
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update -r master clients/\${ID} -s 'webOrigins=["*"]'
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=sonarr -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://sonarr.${DOMAIN_NAME} -s secret=${KEYCLOAK_SONARR_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=radarr -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://radarr.${DOMAIN_NAME} -s secret=${KEYCLOAK_RADARR_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=tdarr -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://tdarr.${DOMAIN_NAME} -s secret=${KEYCLOAK_TDARR_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=sabnzbd -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://sab.${DOMAIN_NAME} -s secret=${KEYCLOAK_SABNZBD_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=code-server -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://code-server.${DOMAIN_NAME} -s secret=${KEYCLOAK_CODE_SERVER_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=duplicati -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://duplicati.${DOMAIN_NAME} -s secret=${KEYCLOAK_DUPLICATI_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r master -s clientId=netdata -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://netdata.${DOMAIN_NAME} -s secret=${KEYCLOAK_NETDATA_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create realms -s realm=user -s id=user -s enabled=true -s bruteForceProtected=true -s displayName=Keycloak -s 'displayNameHtml=<div class="kc-logo-text"><span>Keycloak</span></div>'
ID=\$(docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh get clients -r user -q clientId=account-console --fields id --format csv --noquotes)
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh update -r user clients/\${ID} -s 'webOrigins=["*"]'
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r user -s clientId=ombi -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://ombi.${DOMAIN_NAME} -s secret=${KEYCLOAK_OMBI_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r user -s clientId=overseerr -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://overseerr.${DOMAIN_NAME} -s secret=${KEYCLOAK_OVERSEERR_SECRET}
docker exec keycloak /opt/jboss/keycloak/bin/kcadm.sh create clients -r user -s clientId=jellyfin -s 'redirectUris=["*"]' -s clientAuthenticatorType=client-secret -s alwaysDisplayInConsole=true -s baseUrl=https://jellyfin.${DOMAIN_NAME} -s secret=${KEYCLOAK_JELLYFIN_SECRET}
EOF

cat << EOF > ${CONFIGS_BASE_DIR}/sabnzbd-setup.sh && chown ${USERNAME}:${GROUPNAME} ${CONFIGS_BASE_DIR}/sabnzbd-setup.sh && chmod 700 ${CONFIGS_BASE_DIR}/sabnzbd-setup.sh
#!/bin/bash
sed -r -i 's/(^host_whitelist = .*,).*$/\1sab.${DOMAIN_NAME}/g' ${CONFIGS_BASE_DIR}/sabnzbd/sabnzbd.ini
sed -r -i 's/^local_ranges = .*$/local_ranges = 10., 172., 192., 127./g' ${CONFIGS_BASE_DIR}/sabnzbd/sabnzbd.ini
EOF


