#!/bin/sh

chown postgres -R $PGDATA

if [[ $POSTGRES_TYPE = "MASTER" ]]
then
    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
        sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

        : ${POSTGRES_USER:="postgres"}
        : ${POSTGRES_DB:=$POSTGRES_USER}

        if [ "$POSTGRES_PASSWORD" ]; then
          pass="PASSWORD '$POSTGRES_PASSWORD'"
          authMethod=md5
        else
          echo "==============================="
          echo "!!! Use \$POSTGRES_PASSWORD env var to secure your database !!!"
          echo "==============================="
          pass=
          authMethod=trust
        fi
        echo

        if [ "$POSTGRES_DB" != 'postgres' ]; then
          createSql="CREATE DATABASE $POSTGRES_DB;"
          echo $createSql | gosu postgres postgres --single -jE
          echo
        fi

        if [ "$POSTGRES_USER" != 'postgres' ]; then
          op=CREATE
        else
          op=ALTER
        fi

        userSql="$op USER $POSTGRES_USER WITH SUPERUSER $pass;"
        echo $userSql | gosu postgres postgres --single -jE
        echo

        # internal start of server in order to allow set-up using psql-client
        # does not listen on TCP/IP and waits until start finishes
        gosu postgres pg_ctl -D "$PGDATA" \
            -o "-c listen_addresses=''" \
            -w start

        echo
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)  echo "$0: running $f"; . "$f" ;;
                *.sql) echo "$0: running $f"; psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$f" && echo ;;
                *)     echo "$0: ignoring $f" ;;
            esac
            echo
        done

        gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

        { echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA"/pg_hba.conf
    fi
elif [[ $POSTGRES_TYPE = "SLAVE" ]]
then
    gosu postgres sh -c "PGPASSWORD=\"$POSTGRES_REPLICATION_PASSWORD\" pg_basebackup -h \"$POSTGRES_MASTER\" -D \"$PGDATA\" -U repuser -v -P --xlog-method=stream"
    sed -i -e 's|^#hot_standby.*|hot_standby = on|' "$PGDATA"/postgresql.conf
    gosu postgres cp /usr/share/postgresql/recovery.conf.sample "$PGDATA"/recovery.conf
    sed -i -e 's|^#standby_mode.*|standby_mode = on|' "$PGDATA"/recovery.conf
    sed -i -e "s|^#primary_conninfo.*|primary_conninfo = \'host=$POSTGRES_MASTER port=$POSTGRES_MASTER_TCP_PORT user=repuser password=$POSTGRES_REPLICATION_PASSWORD\'|" "$PGDATA"/recovery.conf
    chmod 0700 "$PGDATA"
fi

exec gosu postgres "$@"
