#!/bin/bash
UPDATER="/etc/cron.daily/netdata-updater"
rm "$UPDATER"
curl https://raw.githubusercontent.com/netdata/netdata/master/packaging/installer/netdata-updater.sh | sed 's@THIS_SHOULD_BE_REPLACED_BY_INSTALLER_SCRIPT@/etc/netdata/.environment@' > $UPDATER
chown root:root $UPDATER
chmod 0755 $UPDATER
