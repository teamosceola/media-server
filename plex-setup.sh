#!/bin/bash
source .env

docker-compose rm -s -v -f plex

if [[ ! $(egrep '^.*AcceptedEULA=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 AcceptedEULA=\"1\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*ManualPortMappingMode=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 ManualPortMappingMode=\"1\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*ManualPortMappingPort=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 ManualPortMappingPort=\"443\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*customConnections=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 customConnections=\"https:\/\/plex.${DOMAIN_NAME}:443,https:\/\/${LAN_IP}:32400\/web,http:\/\/${LAN_IP}:32400\/web\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*PublishServerOnPlexOnlineKey=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 PublishServerOnPlexOnlineKey=\"1\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*FriendlyName=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 FriendlyName=\"plex.${DOMAIN_NAME}\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*ScheduledLibraryUpdatesEnabled=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 ScheduledLibraryUpdatesEnabled=\"1\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*HardwareAcceleratedCodecs=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 HardwareAcceleratedCodecs=\"1\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*TranscoderTempDirectory=.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 TranscoderTempDirectory=\"\/transcode\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*LanNetworksBandwidth==.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 LanNetworksBandwidth==\"10.0.0.0\/8,172.16.10.0\/12,192.168.0.0\/16\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

if [[ ! $(egrep '^.*allowedNetworks===.*$' ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml) ]]
then
    sed -r -i "s/^(<Preferences .*)(\/>)$/\1 allowedNetworks===\"10.0.0.0\/8,172.16.10.0\/12,192.168.0.0\/16\"\2/g" ${CONFIGS_BASE_DIR}/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
fi

docker-compose up -d plex
