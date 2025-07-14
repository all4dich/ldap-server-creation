#!/bin/bash

# This script automates the setup of the OpenLDAP server using Docker.
# It assumes that docker-compose.yaml and all necessary .ldif files are present in the current directory.

# 1. Create local directories for Docker volume mounts
echo "Creating data directories..."
mkdir -p data/ldap data/slapd.d

# 2. Build and start the OpenLDAP and phpLDAPadmin containers in detached mode.
# The --force-recreate flag ensures we start with a clean state if containers already exist.
echo "Starting services with docker-compose..."
docker-compose up -d --force-recreate

# 3. Wait for the LDAP server to initialize properly.
# This is important to ensure the server is ready to accept connections before we try to add data.
echo "Waiting for LDAP server to be ready (10 seconds)..."
sleep 10

# 4. Add the base directory structure (OUs for people, tasks, teams).
echo "Adding base directory structure..."
docker-compose exec openldap ldapadd -x -D "cn=admin,dc=sunjoo,dc=org" -w adminpassword -f /container/service/slapd/assets/test-data/base.ldif

# 5. Add the admin user.
echo "Adding admin user..."
docker-compose exec openldap ldapadd -x -D "cn=admin,dc=sunjoo,dc=org" -w adminpassword -f /container/service/slapd/assets/test-data/admin.ldif

# 6. Add the user 'spark'.
echo "Adding user 'spark'..."
docker-compose exec openldap ldapadd -x -D "cn=admin,dc=sunjoo,dc=org" -w adminpassword -f /container/service/slapd/assets/test-data/user_spark.ldif

# 7. Verify the setup by searching for the newly created user.
echo "Verifying user 'spark' was created..."
ldapsearch -x -H ldap://localhost:389 -b "uid=spark,ou=people,dc=sunjoo,dc=org"

echo -e "\nSetup complete!"
echo "You can access phpLDAPadmin at http://localhost:8080"
echo "Login DN: cn=admin,dc=sunjoo,dc=org"
echo "Password: adminpassword"
