#!/bin/sh
echo -n 'Starting dovecot... '; dovecot -c /etc/dovecot/dovecot.conf && echo "ok." || { echo "failed!"; exit 1; }
echo -n "Launching first run check... "; su -l bm -c "sh /firstrun.sh &"; echo "launched."
echo "Starting Notbit."
while :
do
  if [ -n "$SOCKS_ADDRESS" ]
  then
    su -l user -c "notbit -s 25 -r $SOCKS_ADDRESS -B -D /data/notbit -m /data/maildir -l /data/notbit.log"
  else
    su -l user -c "notbit -s 25 -D /data/notbit -m /data/maildir -l /data/notbit.log"
  fi
  echo -n "Notbit exited with code $?... "; sleep 15: echo "Restarting Notbit."
done

while true
do
  su -l bm -c "notbit -s 2525 -D /data/notbit -m /data/maildir -l /data/notbit.log" & wait ${!}
done
