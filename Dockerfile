FROM alpine:3.13 as builder

SHELL ["/bin/sh", "-euo", "pipefail", "-xc"]

COPY notbit-alpine.patch /usr/local/src/notbit-alpine.patch

RUN apk --no-cache -U upgrade \
	&&  apk --no-cache add \
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
	&& ( cd /usr/local/src \
		&& git clone https://github.com/yshurik/notbit.git ) \
	&& ( cd /usr/local/src/notbit \
		&& git config pull.rebase true \
		&& git config --global user.email "dockerfile@docker.com" \
		&& git config --global user.name "Container Dockerfile" \
		&& git checkout smtp \
		&& git checkout ac873b4e79d07ce1a07a6a6b1a229defc7c3ed06 \
		&& git remote add upstream https://github.com/antorunexe/notbit.git \
		&& git fetch upstream \
		&& git pull upstream master ) \
	&& ( cd /usr/local/src/notbit && ./autogen.sh --prefix=/ ) \
	&& ( cd /usr/local/src/notbit \
		&& patch -p1 < /usr/local/src/notbit-alpine.patch \
		&& make && make install ) \
	&& ldd /bin/notbit && ( /bin/notbit -h || : )



FROM alpine:3.13 as notbit

SHELL ["/bin/sh", "-euo", "pipefail", "-xc"]

RUN apk --no-cache -U upgrade \
	&& apk --no-cache add \
		zlib \
		openssl

COPY --from=builder /bin/notbit /bin/notbit
COPY --from=builder /bin/notbit-keygen /bin/notbit-keygen
COPY --from=builder /bin/notbit-sendmail /bin/notbit-sendmail

COPY entrypoint.sh /entrypoint.sh
COPY firstrun.sh /firstrun.sh
COPY dovecot.conf /etc/dovecot/dovecot.conf

RUN ldd /bin/notbit \
	&& ( /bin/notbit -h || : ) \
	&& mkdir /data \
	&& mkdir /data/notbit \
	&& mkdir /data/maildir \
	&& apk --no-cache add dovecot \
	&& adduser -D user \
	&& echo user:0notbit0 | chpasswd \
	&& ( cd /home/user && ln -s /data/maildir ) \
	&& chown -R -c user:user /data

WORKDIR /home/user
ENV SOCKS_ADDRESS
VOLUME ["/data"]
EXPOSE 25 143 8444
ENTRYPOINT ["/entrypoint.sh"]
