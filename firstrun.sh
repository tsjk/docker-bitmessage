#!/bin/bash
if [ ! -s /data/notbit/keys.dat ]; then
  sleep 30
  A=$(notbit-keygen)
  echo -e "From: $A@bitmessage\\nTo: $A@bitmessage\\nSubject: Welcome to Notbit\\n\\nHello from Notbit,\\n\\nYour address is $A@bitmessage\\n" | notbit-sendmail
fi
