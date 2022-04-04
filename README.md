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
    - [6. Run the Scripts](#7-run-the-scripts)
        - [a. Vars](#a-vars)
        - [b. Setup](#b-setup)
    - [7. Start the Dynamic DNS Client](#8-start-the-dynamic-dns-client)
    - [8. Startup Keycloak](#9-startup-keycloak)
    - [9. Deploy all the things](#10-deploy-all-the-things)
    - [10. Configure SABnzbd](#11-configure-sabnzbd)
- [User Accounts](#user-accounts)
- [Access the Services](#access-the-services)
- [Upgrading Keycloak Postgres Database](#upgrading-keycloak-postgres-database)

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
| A + Dynamic DNS Record | netdata | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | overseerr | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | radarr | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | sab | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | sonarr | 127.0.0.1 | Automatic |
| A + Dynamic DNS Record | tdarr | 127.0.0.1 | Automatic |


## 3. Setup Your Server

I recommend using Ubuntu Server 20.04 LTS on either a pyhsical machine or a VPS.

Requirements:
- docker
- docker-compose
- python3

Make sure to install Docker using the Official install methods from [here](https://docs.docker.com/engine/install/#server)
Don't install docker from Ubuntu's included repos.

And install docker-compose from [here](https://docs.docker.com/compose/install/)

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

## 6. Run the Scripts

### a. Vars

Running the `vars.sh` script will do the following:
- Prompt for Domain Name (first time run only)
- Prompt for NameCheap DDNS Password (first time run only)
- Prompt for Email Address (first time run only)
- Create the `.env` file, which contains auto-generated secrets for Keycloak (including the password for the `admin` account)

Run the `vars.sh` script like this
```
./vars.sh
```
You should see NO output (except for the prompts, first time run only) if everything worked successfully.

Now that the script has ran and created the `.env` file, you should take a look at it.
Pretty much all the things in the `docker-compose.yml` file and other scripts are variabalized and use that `.env` as the source for those variables.
So, if you want to change anything, like directory locations of say your media, now would be the time to change those in the `.env` file before starting any containers.

Also, If there's some service that you don't want to run, now would be the time to comment it out of the `docker-compose.yml` file.

### b. Setup

Running the `setup.sh` script will do the following:
- Create all the necessary directories
- Create the `ddclient.conf` file, which is the config file for the dynamic DNS client
- Create the `letsencrypt/acme.json` file with the correct permissions

Run the `setup.sh` script like this
```
sudo ./setup.sh
```
You should see NO output if everything worked successfully.

After running the script (assuming you kept default directory locations), it will have created the following directory structure:
```
/data
├── backups
├── configs
│   ├── ddclient
│   │   └── ddclient.conf
│   ├── letsencrypt
│   │   └── acme.json
│   └── redis
├── downloads
│   ├── complete
│   └── incomplete
└── media
    ├── movies
    └── tv
```

## 7. Start the Dynamic DNS Client

Start the Dynamic DNS client (ddclient) by running
```
sudo docker-compose up -d ddclient
```
Then login to your [Namecheap Dashboard](https://ap.www.namecheap.com/dashboard), go to domain management, then the advanced dns tab and verify that the IP address for all the records you added earlier have been updated to your current public IP address.

## 8. Startup Keycloak

Start Keycloak by running
```
sudo docker-compose up -d keycloak
```
Now that Keycloak is running, run the `keycloak-setup.sh` script like this
```
sudo ./keycloak-setup.sh
```
The output of this script should look like this:
```
Waiting for Keycloak to finish starting
...
Waiting for Keycloak to finish starting
Logging into http://localhost:8080 as user admin of realm master
Created new realm with id 'user'
Created new client code-server with id 499387df-6fd8-4e16-96ef-5c05c407d727
Created new group code-server with id fde71698-ed21-4f39-bbfa-0021cdd65902
Created new model with id '4a3c2d9c-cb6f-4567-b54f-304b6e07190a'
Created new model with id '2795c948-fcc3-4cc6-8961-2b5ea0f69e21'
Created new role with id 'client-access'
Created new client duplicati with id 0fda4565-5223-43cd-a5fb-ee304e7a9de6
Created new group duplicati with id faa184dc-6d03-479f-9417-75b64bfc2627
Created new model with id '3e7a2fb5-ebae-4175-86c6-6c0d195b029f'
Created new model with id 'a8ddbd2d-758d-4c0d-a731-ebb72a292849'
Created new role with id 'client-access'
Created new client jellyfin with id bb470417-2540-4b3e-a49e-06eeddc35b16
Created new group jellyfin with id d210fadd-cf7c-4f95-bcff-d1f0fbae69a0
Created new model with id 'd7672db5-ff2c-4d29-8fb1-2383477bfd40'
Created new model with id '36ae00c7-3c3a-4ceb-b600-46125ba73aca'
Created new role with id 'client-access'
Created new client netdata with id 99aa4efe-534f-4fcb-9d06-0de6dd09c605
Created new group netdata with id b0a4bbaf-e107-45f2-aa40-c57515528759
Created new model with id 'fad642ad-32c0-4a57-89b0-04a9416c63d3'
Created new model with id 'f43f08b9-9bb3-4e34-b8e6-ee0afdba0eb2'
Created new role with id 'client-access'
Created new client overseerr with id 9f89a298-429c-4d0a-855d-a72c26387edc
Created new group overseerr with id 1fa61374-8c6d-454b-886f-c059ed8612cd
Created new model with id '95525409-85a5-4792-ae26-aec917072051'
Created new model with id '7243207a-c50f-4773-b537-923473de991f'
Created new role with id 'client-access'
Created new client radarr with id be67a3d6-0362-4e81-b0d1-ce4da6a364a3
Created new group radarr with id 4cbb19c4-ce7f-4195-b1da-e80fc5602e22
Created new model with id '057d9aae-7757-426b-8773-b06b15568ffc'
Created new model with id 'e6375970-8268-4f03-9c85-f8229a122e85'
Created new role with id 'client-access'
Created new client sabnzbd with id aa98f3ff-5ca9-41d8-bfb6-3548964fb27e
Created new group sabnzbd with id 83f1b6ed-ed6b-4d43-9073-4249fd78f929
Created new model with id 'dd7b7b83-1663-4fd5-997b-829241704f66'
Created new model with id 'fb1360bb-8e26-4630-ba98-2362b4d832c4'
Created new role with id 'client-access'
Created new client sonarr with id 3f08abf1-f965-4425-a230-ca86173e99ab
Created new group sonarr with id 33f8d431-ef2a-49e6-8b1a-f50774f932e2
Created new model with id '564d3ba8-f183-4dd4-a0f2-eac97eda46a4'
Created new model with id 'e6ff2402-bfd2-4f4b-95aa-a6dd85556a25'
Created new role with id 'client-access'
Created new client tdarr with id 80a0d3d3-37f0-43e1-9624-706e49c237fe
Created new group tdarr with id 620cebae-41d8-4657-a6f2-e75000d7649b
Created new model with id 'da521e38-4005-4ac9-b74e-0dc58b55f70e'
Created new model with id 'ace0d5ab-5397-4893-a50c-3f262c9717ca'
Created new role with id 'client-access'
Role not found for name: client-access
Role not found for name: client-access
Role not found for name: client-access
Role not found for name: client-access
Role not found for name: client-access
Role not found for name: client-access
```
>NOTE: The 6 lines of output at the end like: `Role not found for name: client-access` is expected and OK. This is because the 6 default clients do not have a `client-access` role

## 9. Deploy all the things

To deploy and start all the remaining services run
```
sudo docker-compose up -d
```

## 10. Configure SABnzbd

### Fix Host-Verification Failed

To fix the host-verification failed error when trying to acces SABnzbd run
```
sudo ./sabnzbd-setup.sh
sudo docker-compose restart sabnzbd
```

# User Accounts

You can now get to the Keycloak Administration Console by browsing to `https://auth.<your-domain-name-here>`

Click the Administration Console link, then login with the username `admin`. 

The password for the `admin` account is stored in the `secrets` file. To retrieve it run
```
source .env && echo $KEYCLOAK_ADMIN_PASSWORD
```

Keycloak is confiugred with two realms, the default `master` realm and the `user` realm, which was created by the script.
The builtin `admin` account is in the `master` realm and is the only user account in that realm.
All user accounts that you add will be added to the `user` realm.

There is a `client` and a `group` created for each service in the `user` realm.

User access to each individual service is controlled by group membership.

If you want a user to have access to a particular service, just add their user account to the corresponding group.

There is also an `admin` group, which gives access to all services.

You should leave the default `admin` account exactly as it is.

Services in the `user` realm:
- code-server
- duplicati
- jellyfin
- netdata
- overseerr
- radarr
- sabnzbd
- sonarr
- tdarr

Gropus in the `user` realm:
- admin
- code-server
- duplicati
- jellyfin
- netdata
- overseerr
- radarr
- sabnzbd
- sonarr
- tdarr

Now add your user accounts to Keycloak.

## Add a new user account

To add a user account, login to the Kecloak Admin Console using the `admin` account, the realm will default to the `user` realm.

In the left-hand pane under Manage, click `Users`, then click the `Add user` button.

Fill out the add user form (email is required), check the "Email Verified" box, select the groups for the services the user should have access to (listed above), then click save.

You will then see the "Details" page for the new user.

To set a password for the new user, click on the credentials tab, fill out the password fields, then click "Set Password".

>NOTE: An email address is required for the oauth proxy to work even though it is not a required field by Keycloak, so make sure you set an email address for every user account you add.
    Also, you must select the "Email Verified" box or oauth proxy will return a 500 error.

# Access the Services

>NOTE: you may want to bookmark the "Keycloak (Applications List)" as it has links to all the services

| Service Name | URL |
| ----- | ----- |
| Code-Server | `https://code-server.<your-domain-name-here>` |
| Duplicati | `https://backups.<your-domain-name-here>` |
| Jellyfin | `https://jellyfin.<your-domain-name-here>` |
| Keycloak (Admin Console) | `https://auth.<your-domain-name-here>/admin/master/console/` |
| Keycloak (User Self-Service) | `https://auth.<your-domain-name-here>/realms/user/account/` |
| Keycloak (Applications List) | `https://auth.<your-domain-name-here>/realms/user/account/#/applications` |
| Netdata | `https://netdata.<your-domain-name-here>` |
| Overseerr | `https://overseerr.<your-domain-name-here>` |
| Radarr | `https://radarr.<your-domain-name-here>` |
| Sabnzbd | `https://sab.<your-domain-name-here>` |
| Sonarr | `https://sonarr.<your-domain-name-here>` |
| Tdarr | `https://Tdarr.<your-domain-name-here>` |

# Upgrading Keycloak Postgres Database

## Upgrading Postgres from one major version to the next major version
>NOTE: Will use upgrading from 13 to 14 as an example

1. Edit your `docker-compose.yml` file to make sure the postgres image tag is `postgres:13`, then run:
    ```
    docker-compose up -d postgres-keycloak
    ```

1. Stop the keycloak service by running:
    ```
    docker-compose stop keycloak
    ```

1. Create a backup of the postgres database by running:
    ```
    docker exec -it postgres-keycloak pg_dumpall -U keycloak -f /backups/postgres-keycloak_upgrade.sql
    ```
    >NOTE: The directory `/backups` in the postgres container is a persistent volume configured in the `docker-compose.yml` file for this purpose.
    If you found this guide and are using it for your own setup, you will need to have separate volume attached for the backup.

1. Stop the postgres-keycloak service by running:
    ```
    docker-compose stop postgres-keycloak
    ```

1. Move the old postgres data directory by running:
    ```
    mv postgres postgres.old
    ```

1. Edit your `docker-compose.yml` file to make sure the postgres image tag is now `postgres:14`, then run:
    ```
    docker-compose up -d postgres-keycloak
    ```

1. Restore database from backup by running:
    ```
    docker exec -it postgres-keycloak psql -f /backups/postgres-keycloak_upgrade.sql postgres keycloak
    ```

1. Start the keycloak service by running:
    ```
    docker-compose up -d keycloak
    ```
