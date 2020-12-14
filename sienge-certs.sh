#!/bin/bash

# Because some folders are accessible only to root users
# to run this command, use:

# sudo ./sienge-certs.sh

# Collection of related scripts, and shedulling:
## 1. WIN_SERVER:.../letsencrypt-sienge-autorenew.bat (daily at 05:02am)
## 2. ./sienge-certs.sh (daily at 05:10 am)
## 3. WIN_SERVER:.../sienge-certs-restart.bat (daily at 05:15am)

## Collection of other related files
## 4. WIN_SERVER:.../sienge-certs-schedule.bat 
##	Schedule "script 3" into task of Windows - Run as admin
## 5. WIN_SERVER:.../sienge-certs-status.txt
##	Store variable RESTART_SIENGE=0 (or 1), checked by "script 3"
##	to manage when restart is needed.

## You need to manually do:
## - Copy files 3 and 4 to Windows Server
## - Inside windows server, run script 4 as admin
## - Check if permissions of files is right for Windows
## - Check on Task Scheduler (Graphical Interface), if 
## "letsencrypt-sienge-autorenew.bat" is runing at 05:02am, and if
## the new script "sienge-certs-restart.bat" are scheduled for 05:15am.

CRON_NAME=/etc/cron.d/sienge-certs-cron
LOG=/var/log/sienge-certs.log
CURRENT="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )";

echo "10 05 * * * root $CURRENT/sienge-certs.sh 2>&1 | $CURRENT/timestamp.sh >> $LOG" > $CRON_NAME

chmod 0600 $CRON_NAME
touch $LOG

# Setting some folders

echo; echo "sienge-certs.sh started..."

LIVE=/cygdrive/c/Users/Administrador/AppData/Roaming/letsencrypt-win-simple/httpsacme-v01.api.letsencrypt.org
TEMP_LIVE=./temp_sienge/live/sienge.cpn.com.br
PROXY_CONTAINER=http-proxy
PROXY_CERTS=/home/app/certs/sienge.cpn.com.br
TEMP_PROXY=./temp_sienge/proxy/sienge.cpn.com.br

RESTART_PATH=/cygdrive/d/TI/batch_scripts
TEMP_RESTART_FILE=./temp_sienge/sienge-certs-status.txt

mkdir -p $TEMP_LIVE
mkdir -p $TEMP_PROXY

# Because 'docker cp' command don't follow symlinks correctly,
# We need to copy temporarily with native 'cp' command, 
# -L (follow symlink), -p (preserve name, date, ect), -r (recursivelly, create folder if not exists)
echo -n "Copy certs from live server..."
# copy user ssh credentials to root
cp -r /home/lidio/.ssh/* /root/.ssh/
scp -prq sienge:$LIVE/sienge* $TEMP_LIVE/
echo "Done."

# Copy certs from container to temp folder
echo -n "Copy certs from http-proxy containter..."
docker cp ${PROXY_CONTAINER}:$PROXY_CERTS/. $TEMP_PROXY/
echo "Done."

ISDIFF=0;

diff $TEMP_PROXY/sienge.cpn.com.br-crt.pem $TEMP_LIVE/sienge.cpn.com.br-crt.pem
if [ $? -ne 0 ]; then
        ISDIFF=1;
fi

diff $TEMP_PROXY/sienge.cpn.com.br-key.pem $TEMP_LIVE/sienge.cpn.com.br-key.pem
if [ $? -ne 0 ]; then
        ISDIFF=1;
fi


diff $TEMP_PROXY/sienge.cpn.com.br-chain.pem $TEMP_LIVE/sienge.cpn.com.br-chain.pem
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
        echo "Copy sienge-restart-status to live server..."
	echo "RESTART_SIENGE=1" > $TEMP_RESTART_FILE
	scp -prq $TEMP_RESTART_FILE sienge:$RESTART_PATH/
	#rm $TEMP_RESTART_FILE
        echo "Done."
else
        echo "No changes on certificates.";
fi

# Remove temp files after all checkings
rm -r ./temp_sienge
