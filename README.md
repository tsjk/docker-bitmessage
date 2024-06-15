# Intro

The repository is missing link to run [Bitmessage](http://bitmessage.org)
as a docker container and provide IMAP and SMTP access for communications.

It is based on [Notbit](https://github.com/bpeel/notbit) which is a minimal
client for the network.

That way the bitmessage network can be used with
any compliant mail program such as Thunderbird or Apple Mail.

Also note Notbit is a work in progress and currently has some limitations.
It can already send and receive messages to regular addresses but it
doesn't yet support channels or broadcasts.

The docker image is compact (~20MB) alpine-based, can run on
Linux / Mac / Windows with appropriate setup of Mail client supporting
IMAP and SMTP

# Disclaimer

I am not a cryptography expert and I don't know whether Notbit or the
Bitmessage protocol is actually safe for secure communications. I
wouldn't recommend using for anything highly sensitive.

# Running bitmessage docker container

First you may want to have dedicated docker volume for bitmessage data
(keys etc):

```bash
docker volume create notbit-data
```

Then the docker container can be started with appropriate port mappings for
IMAP (`60143`) and SMTP (`60025`).

```bash
docker run -v notbit-data:/data -d --name notbit \
	-p 8444:8444 -p 127.0.0.1:60025:25 -p 127.0.0.1:60143:143 \
	local/notbit:latest
```

Note that on Mac it can be tricky way to access the volume files directly, so
you may prefer to map just exisitng folder:

```bash
docker run -v /Users/anonymous/notbit-data:/data -d --name notbit \
	-p 8444:8444 -p 127.0.0.1:60025:25 -p 127.0.0.1:60143:143 \
	local/notbit:latest
```


From example above you can setup the Thunderbird to use IMAP from `localhost`,
port `60143`, user: `user`, password: `0notbit0`.
For sending use SMTP `localhost` port `60025` (no auth and credential)

Not that in example above port `60025`,`60143` are mapped to `127.0.0.1` only
so IMAP and SMTP can be accessed only from local machine.

Port `8444` (bitmessage) is mapped to all interfaces to make network
connectivity with other peers.

# Creating an address

On first run (so no keys.dat file `<docker volume>/notbit/keys.dat`) the
initialization script will create your first personal address and send
welcome email from yourself so you identify your `From` address for
further use in emails as sender - appropriate key will be used from
keys.dat.

# Importing addresses

If you already have some addresses from the official PyBitmessage
client you can import these directly by copying over the keys.dat.
file. To do this, make sure the container is stopped then
type:

```bash
docker stop notbit
cp ~/.config/PyBitmessage/keys.dat <docker volume location>/notbit/keys.dat
chown 1001:1001 <docker volume location>/notbit/keys.dat
docker start notbit
```

# Addresses format

The addresses used can not be real email
addresses but instead they must be of the form
`<bitmessage-address>@bitmessage`.

# Messages content-type limitations

Note that any messages you send must have the content type set to
`text/plain` and can't contain any attachments. This means that HTML
messages won't work. They must use either the us-ascii encoding or
UTF-8.
