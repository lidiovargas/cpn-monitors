#!/bin/bash

# Because some folders are accessible only to root users
# to run this command, use:

# sudo ./alfresco-certs.sh

# Adding this script to cron
### Remember to change /etc/cron.d/certbot to values outside the working time
### For example 5:00 am

CRON_NAME=/etc/cron.d/alfresco-certs-cron
LOG=/var/log/alfresco-certs.log
CURRENT="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )";

echo "05 05 * * * root $CURRENT/alfresco-certs.sh 2>&1 | $CURRENT/timestamp.sh >> $LOG" \
        > $CRON_NAME

chmod 0600 $CRON_NAME
touch $LOG

# Setting some folders

echo; echo "alfresco-certs.sh started..."

LIVE=/etc/letsencrypt/live/alfresco.cpn.com.br
TEMP_LIVE=./temp_alfresco/live/alfresco.cpn.com.br
PROXY_CONTAINER=http-proxy
PROXY_CERTS=/home/app/certs/alfresco.cpn.com.br
TEMP_PROXY=./temp_alfresco/proxy/alfresco.cpn.com.br

mkdir -p $TEMP_LIVE
mkdir -p $TEMP_PROXY

# Because 'docker cp' command don't follow symlinks correctly,
# We need to copy temporarily with native 'cp' command, 
# -L (follow symlink), -p (preserve name, date, ect), -r (recursivelly, create folder if not exists)
echo -n "Copy certs from live server..."
cp -pLr $LIVE/* $TEMP_LIVE/
echo "Done."

# Copy certs from container to temp folder
echo -n "Copy certs from http-proxy containter..."
docker cp ${PROXY_CONTAINER}:$PROXY_CERTS/. $TEMP_PROXY/ 
echo "Done."

# Checking differences
echo "Checking differences..."

ISDIFF=0;

diff $TEMP_PROXY/cert.pem $TEMP_LIVE/cert.pem
if [ $? -ne 0 ]; then
	ISDIFF=1;
fi

diff $TEMP_PROXY/chain.pem $TEMP_LIVE/chain.pem
if [ $? -ne 0 ]; then
	ISDIFF=1;
fi


diff $TEMP_PROXY/fullchain.pem $TEMP_LIVE/fullchain.pem
if [ $? -ne 0 ]; then
	ISDIFF=1;
fi

if [ $ISDIFF -eq 1 ]; 
then
	# CODE
	echo "Certificates was changed!";
	echo -n "Copying new certs to http-proxy..."
	docker cp $TEMP_LIVE/. ${PROXY_CONTAINER}:$PROXY_CERTS
	echo "Done."
	echo -n "Restarting container..."
	docker restart http-proxy
	echo "Done."
	echo "Restarting alfresco..."
	/etc/init.d/alfresco restart
	echo "Done."
else
	echo "No changes on certificates.";
fi

# Remove temp files after all checkings
rm -r ./temp_alfresco
