# OpenLDAP Server with Docker Compose

This project provides a quick and easy way to set up a complete OpenLDAP server environment using Docker Compose. It includes an OpenLDAP server, a phpLDAPadmin web interface for easy management, and a set of scripts and configuration files for initial setup.

The LDAP directory is structured with three main organizational units (OUs): `people`, `tasks`, and `teams`.

## Prerequisites

Before you begin, ensure you have the following installed:
- **Docker:** [Get Docker](https://docs.docker.com/get-docker/)
- **Docker Compose:** [Install Docker Compose](https://docs.docker.com/compose/install/)
- **LDAP Client Tools:** (Optional, for command-line verification)
  - On macOS: `brew install openldap`
  - On Debian/Ubuntu: `sudo apt-get install ldap-utils`

## Directory Structure

- `docker-compose.yaml`: Defines the OpenLDAP and phpLDAPadmin services, networks, and volumes.
- `base.ldif`: LDIF file to create the initial directory structure (`ou=people`, `ou=tasks`, `ou=teams`).
- `admin.ldif`: LDIF file to create the administrative user.
- `user_sunjoopark.ldif`: An example LDIF file for creating a new user.
- `all-commands.sh`: A helper script to automate the entire setup process.
- `dex-ldap-config.yaml`: An example Dex configuration for integrating with Kubeflow.
- `data/`: Directory used for persistent LDAP data and configuration.

## Quick Start

The included `all-commands.sh` script automates the entire setup process.

1.  **Make the script executable:**
    ```bash
    chmod +x all-commands.sh
    ```

2.  **Run the script:**
    ```bash
    ./all-commands.sh
    ```
    This script will create the necessary data directories, start the containers, and import all the initial `.ldif` files.

## Manual Setup Steps

If you prefer to run the steps manually, follow this guide.

1.  **Create Data Directories:**
    Create local directories that will be mounted as volumes for persistent data storage.
    ```bash
    mkdir -p data/ldap data/slapd.d
    ```

2.  **Start the Services:**
    Bring up the OpenLDAP and phpLDAPadmin containers in detached mode.
    ```bash
    docker-compose up -d
    ```

3.  **Import LDIF Files:**
    Wait a few seconds for the server to initialize, then execute the `ldapadd` command inside the `openldap` container for each `.ldif` file. The files are mounted into the container automatically by the `docker-compose.yaml` configuration.

    ```bash
    # Add the base structure
    docker-compose exec openldap ldapadd -x -D "cn=admin,dc=sunjoo,dc=org" -w adminpassword -f /container/service/slapd/assets/test-data/base.ldif

    # Add the admin user
    docker-compose exec openldap ldapadd -x -D "cn=admin,dc=sunjoo,dc=org" -w adminpassword -f /container/service/slapd/assets/test-data/admin.ldif

    # Add the example user 'sunjoopark'
    docker-compose exec openldap ldapadd -x -D "cn=admin,dc=sunjoo,dc=org" -w adminpassword -f /container/service/slapd/assets/test-data/user_sunjoopark.ldif
    ```

## Verification

1.  **Check Container Status:**
    Ensure both containers are running.
    ```bash
    docker-compose ps
    ```
    You should see both `openldap` and `phpldapadmin` with a `Up` status.

2.  **Search the LDAP Directory:**
    Use `ldapsearch` to query the directory and verify that the entries were created successfully.
    ```bash
    # Search for the user 'sunjoopark'
    ldapsearch -x -H ldap://localhost:389 -b "uid=sunjoopark,ou=people,dc=sunjoo,dc=org"
    ```

## Accessing Services

### phpLDAPadmin (Web UI)

- **URL:** [http://localhost:8080](http://localhost:8080)
- **Login DN:** `cn=admin,dc=sunjoo,dc=org`
- **Password:** `adminpassword`

### OpenLDAP Server

- **Host:** `localhost`
- **Port:** `389` (LDAP) / `636` (LDAPS - currently disabled)
- **Admin DN:** `cn=admin,dc=sunjoo,dc=org`
- **Admin Password:** `adminpassword`
- **Base DN:** `dc=sunjoo,dc=org`

## Adding More Users

To add another user:
1.  Create a new file (e.g., `new_user.ldif`) with the user's details.
2.  Add the new file to the `volumes` section of the `openldap` service in `docker-compose.yaml`.
3.  Restart the services: `docker-compose up -d --force-recreate`.
4.  Run `ldapadd` to import the new file.

## Kubeflow Dex Integration

The `dex-ldap-config.yaml` file contains a sample configuration for connecting Dex to this LDAP server.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dex
  namespace: auth # Or your Kubeflow namespace
data:
  config.yaml: |
    issuer: http://<DEX_SERVICE_URL>:5556
    storage:
      type: sqlite3
      config:
        file: /tmp/dex.db
    web:
      http: 0.0.0.0:5556
    connectors:
    - type: ldap
      id: ldap
      name: "LDAP"
      config:
        host: openldap:389
        insecureNoSSL: true
        bindDN: "cn=admin,dc=sunjoo,dc=org"
        bindPW: "adminpassword"
        userSearch:
          baseDN: "ou=people,dc=sunjoo,dc=org"
          username: "uid"
          idAttr: "uid"
          emailAttr: "mail"
          nameAttr: "cn"
        groupSearch:
          baseDN: "ou=teams,dc=sunjoo,dc=org"
          filter: "(objectClass=groupOfNames)"
          userAttr: "dn"
          groupAttr: "member"
          nameAttr: "cn"
```
**Note:** You will need to adjust the `host` and `issuer` depending on your network setup between Kubernetes and Docker.

## Cleanup

To stop and remove the containers and network, run:
```bash
docker-compose down
```
To also remove the persistent data volumes, run:
```bash
docker-compose down -v
```
