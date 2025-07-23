#! /bin/bash

echo Checking if auto-dnsbl is running

if [ -f /var/lock/subsys/auto-dnsbl ]; then

    echo -e "\033[1;31mError!"
    echo
    echo -e "Auto-dnsbl is running please run /etc/rc.d/init.d/auto-dnsbl stop"
    echo
    echo -e "See README for details\033[0m"
    echo
    
    exit 1
fi

echo Removing files

rm -f /etc/rc.d/init.d/auto-dnsbl
rm -f /usr/local/bin/auto-dnsbl.pl
rm -f /run/auto-dnsbl.state.dir
rm -f /run/auto-dnsbl.state.pag

echo Removing links

rm -f /etc/rc.d/rc0.d/K75auto-dnsbl
rm -f /etc/rc.d/rc3.d/S50auto-dnsbl
rm -f /etc/rc.d/rc6.d/K75auto-dnsbl

echo Restore log.dat

mv /srv/web/ipfire/cgi-bin/logs.cgi/log.dat.orig /srv/web/ipfire/cgi-bin/logs.cgi/log.dat

echo Removing Whitelist

rm -f /var/ipfire/auto-dnsbl/whitelist
rmdir /var/ipfire/auto-dnsbl

echo Delete any Rules in AUTO-DNSBL chain

iptables -F AUTO-DNSBL

echo Stopping firewall.local

/etc/sysconfig/firewall.local stop

echo Removing firewall rules and chains

mv /etc/sysconfig/firewall.local.orig /etc/sysconfig/firewall.local

echo Restarting firewall.local

/etc/sysconfig/firewall.local start


echo Done
