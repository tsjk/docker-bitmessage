FROM alpine:3.20 as builder

SHELL ["/bin/sh", "-euo", "pipefail", "-xc"]

COPY notbit /usr/local/src/notbit
COPY 0000-misc_patches.patch /usr/local/src/notbit/0000-misc_patches.patch

RUN	   apk --no-cache -U upgrade\
	&& apk --no-cache add\
		gcc\
		g++\
		libc-dev\
		zlib-dev\
		openssl-dev\
		autoconf\
		automake\
		make\
		patch\
	&& ( cd /usr/lib && ln -s libboost_thread-mt.so libboost_thread.so )\
	&& ( cd /usr/local/src/notbit\
		&& ./autogen.sh --prefix=/ )\
	&& ( cd /usr/local/src/notbit\
		&& patch -p1 < /usr/local/src/notbit/0000-misc_patches.patch )\
	&& ( cd /usr/local/src/notbit\
		&& make NOTBIT_EXTRA_CFLAGS="-Wno-deprecated-declarations" && make install )\
	&& ldd /bin/notbit\
	&& { /bin/notbit -h || true; } > /tmp/notbit.out 2>&1\
	&& grep -q -E '^Notbit - a Bitmessage → maildir daemon\.' /tmp/notbit.out\
	&& rm /tmp/notbit.out


FROM alpine:3.20 as notbit

ARG UID=1001

SHELL ["/bin/sh", "-euo", "pipefail", "-xc"]

COPY --from=builder /bin/notbit /bin/notbit
COPY --from=builder /bin/notbit-keygen /bin/notbit-keygen
COPY --from=builder /bin/notbit-sendmail /bin/notbit-sendmail

RUN	   apk --no-cache -U upgrade\
	&& apk --no-cache add\
		zlib\
		openssl\
		icu-data-full\
		dovecot\
		tini\
		bash\
		su-exec\
	&& mv /etc/dovecot /etc/dovecot-alpine\
	&& mkdir /etc/dovecot\
	&& ldd /bin/notbit\
	&& { /bin/notbit -h || true; } > /tmp/notbit.out 2>&1\
	&& grep -q -E '^Notbit - a Bitmessage → maildir daemon\.' /tmp/notbit.out\
	&& rm /tmp/notbit.out\
	&& mkdir /data\
	&& mkdir /data/notbit\
	&& mkdir /data/maildir\
	&& adduser -u ${UID} -D user\
	&& echo user:0notbit0 | chpasswd\
	&& ( cd /home/user && ln -s /data/maildir )\
	&& chown -R -c user:user /data

COPY entrypoint.sh /entrypoint.sh
COPY firstrun.sh /firstrun.sh
COPY dovecot.conf /etc/dovecot/dovecot.conf

WORKDIR /home/user
ENV SOCKS_ADDRESS=""
VOLUME ["/data"]
EXPOSE 8444 60025 60143
ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
