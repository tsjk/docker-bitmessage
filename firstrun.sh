#!/bin/sh
sleep 30
if [ ! -f /data/notbit/keys.dat ]
then
	export A=$(notbit-keygen)
	echo -e "From: $A@bitmessage\\nTo: $A@bitmessage\\nSubject: Welcome to Notbit\\n\\nHello from Notbit,\\n\\nYour address is $A@bitmessage\\n" | \
		notbit-sendmail
fi
