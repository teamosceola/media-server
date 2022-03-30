#!/bin/bash
source .env

# wait for keycloak to become ready
until [[ $(docker logs keycloak 2> /dev/null | egrep '^.*\(main\) Keycloak.*on JVM.*started in.*Listening on: http://0\.0\.0\.0:8080$' > /dev/null ; echo $?) -eq "0" ]]
do
        echo "Waiting for Keycloak to finish starting"
        sleep 5
done
sleep 5

# login
docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password "${KEYCLOAK_ADMIN_PASSWORD}"

# enable brute force protection in master realm
docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/master -s enabled=true -s bruteForceProtected=true

# add email to admin user
ID=$(docker exec keycloak /opt/keycloak/bin/kcadm.sh get users -c -r master -q username=admin --fields id --format csv --noquotes)
docker exec keycloak /opt/keycloak/bin/kcadm.sh update users/${ID} -s "email=admin@${DOMAIN_NAME}"

# fix account managment console in master realm
ID=$(docker exec keycloak /opt/keycloak/bin/kcadm.sh get clients -r master -q clientId=account-console --fields id --format csv --noquotes)
docker exec keycloak /opt/keycloak/bin/kcadm.sh update -r master clients/${ID} -s 'webOrigins=["*"]'

# create user realm
docker exec keycloak /opt/keycloak/bin/kcadm.sh create realms -s realm=user -s id=user -s enabled=true \
  -s bruteForceProtected=true -s displayName=Keycloak -s 'displayNameHtml=<div class="kc-logo-text"><span>Keycloak</span></div>'

# fix account managment console in user realm
ID=$(docker exec keycloak /opt/keycloak/bin/kcadm.sh get clients -r user -q clientId=account-console --fields id --format csv --noquotes)
docker exec keycloak /opt/keycloak/bin/kcadm.sh update -r user clients/${ID} -s 'webOrigins=["*"]'

# function to create and configure keycloak clients
# creates the client
# add protocol mappers
# creates client role
# creates client group
# adds client role to client group
# parameters: 1) client-id, 2) app-fqdn, 3) client-secret
function create_keycloak_client () {
    ID=$(docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        create clients \
        -r user \
        -s clientId=$1 \
        -s "redirectUris=[\"https://$2/oauth2/callback\"]" \
        -s clientAuthenticatorType=client-secret \
        -s alwaysDisplayInConsole=true \
        -s baseUrl=https://$2 \
        -s secret=$3 \
        2>&1 | cut -d"'" -f 2)
    GID=$(docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        create groups \
        -r user \
        -s name=$1 \
        2>&1 | cut -d"'" -f 2)
    echo Created new client $1 with id ${ID}
    echo Created new group $1 with id ${GID}
    docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        create clients/${ID}/protocol-mappers/models \
        -r user \
        -s 'name=groups' \
        -s 'protocol=openid-connect' \
        -s 'protocolMapper=oidc-group-membership-mapper' \
        -s 'consentRequired=false' \
        -s 'config."full.path"=true' \
        -s 'config."id.token.claim"=true' \
        -s 'config."access.token.claim"=true' \
        -s 'config."claim.name"=groups' \
        -s 'config."userinfo.token.claim"=true'
    docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        create clients/${ID}/protocol-mappers/models \
        -r user \
        -s "name=$1-audience" \
        -s 'protocol=openid-connect' \
        -s 'protocolMapper=oidc-audience-mapper' \
        -s 'consentRequired=false' \
        -s "config.\"included.client.audience\"=$1" \
        -s 'config."id.token.claim"=false' \
        -s 'config."access.token.claim"=true' \
        -s 'config."claim.name"=groups' \
        -s "config.\"included.custom.audience\"=$1"
    docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        create clients/${ID}/roles \
        -r user \
        -s 'name=client-access' \
        -s 'composite=false' \
        -s 'clientRole=true'
    docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        add-roles \
        -r user \
        --gid ${GID} \
        --cid ${ID} \
        --rolename client-access
}

# create 'code-server' client
create_keycloak_client code-server code-server.${DOMAIN_NAME} ${KEYCLOAK_CODE_SERVER_SECRET}

# create 'duplicati' client
create_keycloak_client duplicati backups.${DOMAIN_NAME} ${KEYCLOAK_DUPLICATI_SECRET}

# create 'jellyfin' client
create_keycloak_client jellyfin jellyfin.${DOMAIN_NAME} ${KEYCLOAK_JELLYFIN_SECRET}

# create 'netdata' client
create_keycloak_client netdata netdata.${DOMAIN_NAME} ${KEYCLOAK_NETDATA_SECRET}

# create 'overseerr' client
create_keycloak_client overseerr overseerr.${DOMAIN_NAME} ${KEYCLOAK_OVERSEERR_SECRET}

# create 'radarr' client
create_keycloak_client radarr radarr.${DOMAIN_NAME} ${KEYCLOAK_RADARR_SECRET}

# create 'sabnzbd' client
create_keycloak_client sabnzbd sab.${DOMAIN_NAME} ${KEYCLOAK_SABNZBD_SECRET}

# create 'sonarr' client
create_keycloak_client sonarr sonarr.${DOMAIN_NAME} ${KEYCLOAK_SONARR_SECRET}

# create 'tdarr' client
create_keycloak_client tdarr tdarr.${DOMAIN_NAME} ${KEYCLOAK_TDARR_SECRET}

# create 'admin' group
ADMIN_GID=$(docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        create groups \
        -r user \
        -s name=admin 2>&1 \
        | cut -d"'" -f 2)

# add client roles to 'admin' group
for client in $(docker exec keycloak /opt/keycloak/bin/kcadm.sh get clients -r user --fields id --format csv | cut -d'"' -f 2)
do
    docker exec keycloak /opt/keycloak/bin/kcadm.sh \
        add-roles \
        -r user \
        --gid ${ADMIN_GID} \
        --cid ${client} \
        --rolename client-access 2>&1
done