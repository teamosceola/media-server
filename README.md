# README

## Description

A home media server setup script that uses docker-compose for container orchestration, Traefik reverse proxy with LetsEncrypt SSL certificates, Keycloak for SSO, and oauth2-proxy for full authenticating proxy.

## Outline

- [How to Get it Deployed](#how-to-get-it-deployed)
    - [1. Get a Domain Name](#1-get-a-domain-name)
    - [2. Configure Namecheap DDNS](#2-configure-namecheap-ddns)
    - [3. Setup Your Server](#3-setup-your-server)
    - [4. Setup Port Forwarding](#4-setup-port-forwarding)
    - [5. Clone The Repo](#5-clone-the-repo)
    - [6. Edit the variables in `media-server.sh`](#6-edit-the-variables-in-media-server.sh)
    - [7. Run the Script](#7-run-the-script)
    - [8. Start the Dynamic DNS Client](#8-start-the-dynamic-dns-client)
    - [9. Startup Keycloak](#9-startup-keycloak)
    - [10. Deploy all the things](#10-deploy-all-the-things)
    - [11. Configure SABnzbd](#11-configure-sabnzbd)
- [User Accounts](#user-accounts)
- [Access the Services](#access-the-services)

# How to Get it Deployed

## 1. Get a Domain Name

Get a domain name from [Namecheap](https://www.namecheap.com/).
It's important to use [Namecheap](https://www.namecheap.com/) because the dynamic DNS client configuration depends on it.
If you don't want to use [Namecheap](https://www.namecheap.com/), then you are on your own for modifying the `ddclient.conf` file.

## 2. Configure Namecheap DDNS

- From your [Namecheap Dashboard](https://ap.www.namecheap.com/dashboard), click on the `MANAGE` button for your domain.
- Turn off the "Parking page".
- Go to the `Advanced DNS` tab.
- Turn on `Dynamic DNS` and copy your `Dynamic DNS Password` that was generated for you and save it somewhere handy as you will need it later.
- Add the following records from the table:

| Type | Host | Value | TTL |
| ----- | ----- | ----- | ----- |
| A + Dynamic DNS Record | @ | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | auth | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | backups | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | code-server | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | jellyfin | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | ombi | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | overseerr | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | radarr | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | sab | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | sonarr | 127.0.0.1 | Automatic |


## 3. Setup Your Server

I recommend using Ubuntu Server 20.04 LTS on either a pyhsical machine or a VPS.

Requirements:
- docker
- docker-compose
- python3

Run `sudo apt update && sudo apt upgrade -y` then reboot to make sure you are fully updated

Configure your firewall. At a minimum you will want TCP ports 22, 80, and 443 open. It's also nice to open TCP port 8080, which is the [Traefik](https://github.com/traefik/traefik) dashboard.

## 4. Setup Port Forwarding

Configure your router to forward ports 80 and 443 to your server's LAN IP address.
This is not applicable if your server has a public IP address.

## 5. Clone The Repo

Login to your server and clone this repo by runnig
```
git clone https://github.com/teamosceola/media-server.git
```

## 6. Edit the variables in `media-server.sh`

Required variables that need setting:
- `DOMAIN_NAME`
- `NC_DDNS_PASS`
- `EMAIL`

Optional variables that can be modified, but have default values that will work:
- `CONFIGS_BASE_DIR=/data/configs`
- `MEDIA_BASE_DIR=/data/media`
- `TV_MEDIA_DIR=${MEDIA_BASE_DIR}/tv`
- `MOVIE_MEDIA_DIR=${MEDIA_BASE_DIR}/movies`
- `DOWNLOADS=/data/downloads/complete`
- `INCOMPLETE_DOWNLOADS=/data/downloads/incomplete`
- `BACKUPS_DIR=/data/backups`

## 7. Run the Script

Running the `media-server.sh` script will do the following:
- Create all the necessary directories
- Create the `secrets` file, which contains auto-generated secrets for Keycloak (including the password for the `admin` account)
- Create the `ddclient.conf` file, which is the config file for the dynamic DNS client
- Create you `docker-compose.yml` file
- Create a customized `keycloak-setup.sh` script that will be used to configure Keycloak after it's been deployed

Run the `media-server.sh` script like this
```
./media-server.sh
```
You should see NO output if everything worked successfully.

After running the script (assuming you kept default directory locations), it will have created the following directory structure:
```
/data
├── backups
├── configs
│   ├── ddclient
│   │   └── ddclient.conf
│   ├── docker-compose.yml
│   ├── keycloak-setup.sh
│   ├── letsencrypt
│   │   └── acme.json
│   ├── redis
│   └── secrets
├── downloads
│   ├── complete
│   └── incomplete
└── media
    ├── movies
    └── tv
```

## 8. Start the Dynamic DNS Client

Change to your configs directory (`/data/configs` is the default) and run
```
docker-compose up -d ddclient
```
Then login to your [Namecheap Dashboard](https://ap.www.namecheap.com/dashboard), go to domain management, then the advanced dns tab and verify that the IP address for all the records you added earlier have been updated to your current public IP address.

## 9. Startup Keycloak

Start Keycloak by running
```
docker-compose up -d keycloak
```
Now that Keycloak is running, run the `keycloak-setup.sh` script like this
```
./keycloak-setup.sh
```
The output of this script should look like this:
```
Waiting for Keycloak to finish starting
...
Waiting for Keycloak to finish starting
Logging into http://localhost:8080/auth as user admin of realm master
Created new client with id '09eebd13-e063-45cc-86b4-48b6d2ffad7b'
Created new client with id '35d3a671-c6a8-4362-9dbb-6aa1d277d007'
Created new client with id 'ccda169a-25df-4f4b-9c02-d66dab1eea5c'
Created new client with id '8638db46-44a0-4192-be6c-b46af4b46319'
Created new client with id '17234985-f9fe-4ce2-aaf6-6ff6e8ed95f0'
Created new realm with id 'user'
Created new client with id '611a256b-f682-4929-9c18-de6f50d202bc'
Created new client with id '00fdab54-f91d-4082-afb8-6c0ec2034b6c'
Created new client with id '5ff478fc-ae16-4970-a0e2-1deee4669f30'
```

## 10. Deploy all the things

To deploy and start all the remaining services run
```
docker-compose up -d
```

## 11. Configure SABnzbd

### Fix Host-Verification Failed

To fix the host-verification failed error when trying to acces SABnzbd run
```
./sabnzbd-setup.sh
docker-compose restart sabnzbd
```

# User Accounts

You can now get to the Keycloak Administration Console by browsing to `https://auth.<your-domain-name-here>/auth/`

Click the Administration Console link, then login with the username `admin`. 

The password for the `admin` account is stored in the `secrets` file. To retrieve it run
```
source secrets && echo $KEYCLOAK_ADMIN_PASSWORD
```

Keycloak is confiugred with two realms, a `master` realm and a `user` realm.
Each service is tied to a specific realm, so if you want a user account to have access to all services, you have to create two identical user accounts, one in the `master` realm and one in the `user` realm.
Most accounts will only exist in the `user` realm, while only the person who owns/administers the server will need the duplicated account in the `master` realm.
You should leave the default `admin` account exactly as it is.

Services in the `master` realm:
- code-server
- duplicati
- radarr
- sabnzbd
- sonarr

Services in the `user` realm:
- jellyfin
- ombi
- overseerr

Now add your user accounts to Keycloak. 

>NOTE: An email address is required for the oauth proxy to work even though it is not a required field by Keycloak, so make sure you set an email address for every user account you add.

# Access the Services

| Service Name | URL |
| ----- | ----- |
| Code-Server | `https://code-server.<your-domain-name-here>` |
| Duplicati | `https://backups.<your-domain-name-here>` |
| Jellyfin | `https://jellyfin.<your-domain-name-here>` |
| Keycloak (Admin Console) | `https://auth.<your-domain-name-here>/auth/admin/master/console/` |
| Keycloak (User Self-Service) | `https://auth.<your-domain-name-here>/auth/realms/user/account/` |
| Radarr | `https://radarr.<your-domain-name-here>` |
| Ombi | `https://ombi.<your-domain-name-here>` |
| Overseerr | `https://overseerr.<your-domain-name-here>` |
| Radarr | `https://radarr.<your-domain-name-here>` |
| Sabnzbd | `https://sab.<your-domain-name-here>` |
| Sonarr | `https://sonarr.<your-domain-name-here>` |
