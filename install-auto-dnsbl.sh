#! /bin/bash

# Download the manifest

  wget "https://people.ipfire.org/~helix/auto-dnsbl/MANIFEST"

  # Download and move files to their destinations

echo Downloading files

  if [[ ! -r MANIFEST ]]; then
    echo "Can't find MANIFEST file"
    exit 1
  fi

  while read -r name path owner mode || [[ -n "$name" ]]; do
    echo --
    echo Download $name
    echo $path
     if [[ ! -d $path ]]; then mkdir -p $path; fi
     if [[ $name != "." ]];
     then
       wget "https://people.ipfire.org/~helix/auto-dnsbl/$name" -O $path/$name
       chown $owner $path/$name
       chmod $mode $path/$name;
      else
        chown $owner $path
        chmod $mode $path;
     fi
   done < "MANIFEST"

  # Tidy up

  rm MANIFEST

echo Add start/stop links

if [[ ! -e /etc/rc.d/rc0.d/K75auto-dnsbl ]]; then
  ln -s /etc/rc.d/init.d/auto-dnsbl  /etc/rc.d/rc0.d/K75auto-dnsbl;
fi

if [[ ! -e /etc/rc.d/rc3.d/S50auto-dnsbl ]]; then
  ln -s /etc/rc.d/init.d/auto-dnsbl  /etc/rc.d/rc3.d/S50auto-dnsbl;
fi

if [[ ! -e /etc/rc.d/rc6.d/K75auto-dnsbl ]]; then
  ln -s /etc/rc.d/init.d/auto-dnsbl  /etc/rc.d/rc6.d/K75auto-dnsbl;
fi

echo patch add auto-dnsbl log.dat

patch -b /srv/web/ipfire/cgi-bin/logs.cgi/log.dat log.dat.patch

rm -f log.dat.patch

echo add whitelist file

touch /var/ipfire/auto-dnsbl/whitelist
chown root.root /var/ipfire/auto-dnsbl/whitelist
chmod 644 /var/ipfire/auto-dnsbl/whitelist

echo Generate firewall rules

MAILADDR=$(iptables -S FORWARDFW | grep "dport 25" |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

cp /etc/sysconfig/firewall.local /etc/sysconfig/firewall.local.orig

if [ ! -s $MAILADDR ]; then

        echo Stopping firewall.local
        /etc/sysconfig/firewall.local stop

        STARTCHAIN="    # Add new chain AUTO-DNSBL
        /sbin/iptables -N AUTO-DNSBL
        /sbin/iptables -I FORWARD 5 -j AUTO-DNSBL

        # Add firewall rule to log incomming smtpconnections
        iptables -I FORWARDFW -i ppp0 -p tcp -d "$MAILADDR" --dport 25 --syn -j LOG --log-prefix='[smtpconnections] '\n"

        STOPCHAIN="     # Remove chain AUTO-DNSBL
        /sbin/iptables -D FORWARD -j AUTO-DNSBL
        /sbin/iptables -X AUTO-DNSBL

        # Delete firewall rule to log incomming smtpconnections
        iptables -D FORWARDFW -i ppp0 -p tcp -d "$MAILADDR" --dport 25 --syn -j LOG --log-prefix='[smtpconnections] '\n"

        sed -i '/## add your '\''start'\'' rules here/{n;r'<(echo -e "$STARTCHAIN")$'\n}' /etc/sysconfig/firewall.local
        sed -i '/## add your '\''stop'\'' rules here/{n;r'<(echo -e "$STOPCHAIN")$'\n}' /etc/sysconfig/firewall.local

        echo Restarting firewall.local
        /etc/sysconfig/firewall.local start
else
        echo -e "\033[1;31mError!"
        echo
        echo "Unable to find Port 25 FORWARD rule"
        echo
        echo "You need to configure firewall.local manually"
        echo
        echo -e "See README for details\033[0m"
        echo

fi

echo Installation complete
echo
echo You now need to configure /usr/local/bin/auto-dnsbl.pl
echo
echo See README for options
echo
echo To start auto-dnsbl run /etc/rc.d/init.d/auto-dnsbl start
echo

