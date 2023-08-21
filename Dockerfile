FROM alpine:3.16 as builder

SHELL ["/bin/sh", "-euo", "pipefail", "-xc"]

COPY notbit-alpine.patch /usr/local/src/notbit-alpine.patch

RUN	   apk --no-cache -U upgrade \
	&& apk --no-cache add \
		gcc \
		g++ \
		libc-dev \
		zlib-dev \
		openssl-dev \
		git \
		autoconf \
		automake \
		make \
		patch \
	&& ( cd /usr/lib && ln -s libboost_thread-mt.so libboost_thread.so ) \
	&& mkdir -p /usr/local/src \
	&& git config --global user.email "dockerfile@docker.com" \
	&& git config --global user.name "Container Dockerfile" \
	&& ( cd /usr/local/src \
		&& git clone -b smtp https://github.com/yshurik/notbit.git ) \
	&& ( cd /usr/local/src/notbit && ./autogen.sh --prefix=/ ) \
	&& ( cd /usr/local/src/notbit \
		&& patch -p1 < /usr/local/src/notbit-alpine.patch )\
	&& ( cd /usr/local/src/notbit \
		&& make && make install ) \
	&& ldd /bin/notbit \
	&& { /bin/notbit -h || true; } > /tmp/notbit.out 2>&1\
	&& grep -q -E '^Notbit - a Bitmessage → maildir daemon\.' /tmp/notbit.out\
	&& rm /tmp/notbit.out


FROM alpine:3.16 as notbit

SHELL ["/bin/sh", "-euo", "pipefail", "-xc"]

COPY --from=builder /bin/notbit /bin/notbit
COPY --from=builder /bin/notbit-keygen /bin/notbit-keygen
COPY --from=builder /bin/notbit-sendmail /bin/notbit-sendmail

COPY entrypoint.sh /entrypoint.sh
COPY firstrun.sh /firstrun.sh
COPY dovecot.conf /etc/dovecot/dovecot.conf

RUN	   apk --no-cache -U upgrade\
	&& apk --no-cache add\
		zlib\
		openssl\
		icu-data-full\
		dovecot\
	&& ldd /bin/notbit \
	&& { /bin/notbit -h || true; } > /tmp/notbit.out 2>&1\
	&& grep -q -E '^Notbit - a Bitmessage → maildir daemon\.' /tmp/notbit.out\
	&& rm /tmp/notbit.out\
	&& mkdir /data \
	&& mkdir /data/notbit \
	&& mkdir /data/maildir \
	&& adduser -u 1001 -D user \
	&& echo user:0notbit0 | chpasswd \
	&& ( cd /home/user && ln -s /data/maildir ) \
	&& chown -R -c user:user /data

WORKDIR /home/user
ENV SOCKS_ADDRESS=""
VOLUME ["/data"]
EXPOSE 25 143 8444
ENTRYPOINT ["/entrypoint.sh"]
