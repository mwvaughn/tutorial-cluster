#!/usr/bin/env bash

# Generates an LDIF file that can be used to populate a directory service

# How many users to generate
COUNT=${1:-100}

for U in $(seq ${COUNT})
do
UNAME="train${U}"
USERID=$(expr ${U} + 1001)
cat << BLOCK
# Add user ${UNAME}
dn: CN=${UNAME},OU=Users,OU=corp,DC=corp,DC=pcluster,DC=com
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: ${UNAME}
name: ${UNAME}
userPrincipalName: ${UNAME}@corp.pcluster.com
mail: ${UNAME}@corp.pcluster.com
uidNumber: ${USERID}
gidNumber: ${USERID}
unixHomeDirectory: /home/${UNAME}
loginShell: /bin/bash
userPassword: ${UNAME}.

BLOCK
done
