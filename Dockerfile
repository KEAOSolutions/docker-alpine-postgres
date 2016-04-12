# Postgres on Alpine Linux
FROM ukhomeoffice/glibc:latest

RUN apk add --update postgresql && \
    mkdir /docker-entrypoint-initdb.d
RUN rm -rf /var/cache/apk/*

ENV PGDATA /var/lib/postgresql/data
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /
ADD docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
