# PostgreSQL docker image based on Alpine Linux

This repo builds a docker image that accepts the same env vars as the
[official postgres build](https://registry.hub.docker.com/_/postgres/) but
with a much smaller footprint. It achieves that by basing itself off the great
[alpine](https://github.com/gliderlabs/docker-alpine) docker image by GliderLabs.

## Postgres Password creation

Set the postgres password as follows
```
$ python
>>> import hashlib
>>> pghash = "md5" + hashlib.md5('FUDG3N0w' + 'repuser').hexdigest()
>>> print pghash
md5f350fb1958654116fa4c548d39869f02
```

Postgres user Password for example: fudge
Postgres Replication user Password for example: FUDG3N0w

To build the Postgres image run 
```
make build
```

To run the Master Server run:
```
make master
```

To run the Slave Server run:
```
make slave
```

To get a psql session direct on the master you can attach to it and run:
```
make debug
gosu postgres psql
```

## TODO
* Test flipping master to slave
* Add SSL support for Client / Server


