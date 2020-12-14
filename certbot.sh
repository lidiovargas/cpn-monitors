# Run this script as root:
## sudo ./certbot.sh

CRON_NAME=/etc/cron.d/certbot
LOG=/var/log/certbot.log
CURRENT="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )";


echo "
# /etc/cron.d/certbot: crontab entries for the certbot package
#
# Upstream recommends attempting renewal twice a day
#
# Eventually, this will be an opportunity to validate certificates
# haven't been revoked, etc.  Renewal will only occur if expiration
# is within 30 days.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

### Original with default installation
# 00 05 * * * root test -x /usr/bin/certbot -a \! -d /run/systemd/system && perl -e 'sleep int(rand(43200))' && certbot -q renew 

00 05 * * * * root certbot renew 2>&1 | $CURRENT/timestamp.sh >> $LOG

" > $CRON_NAME

chmod 0600 $CRON_NAME
touch $LOG
