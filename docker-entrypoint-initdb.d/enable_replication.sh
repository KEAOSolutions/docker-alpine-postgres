#/usr/bin/env bash

POSTGRES_REPLICATION_PASSWORD=${POSTGRES_REPLICATION_PASSWORD:=md5f350fb1958654116fa4c548d39869f02}

if [[ $POSTGRES_REPLICATION = "ON" ]] 
then
    gosu postgres mkdir -p "$PGDATA"/mnt/server/archive
    sed -i -e '/^host replication repuser/{h;s|^host replication repuser.*|host replication repuser 0.0.0.0/0 md5|};${x;/^$/{s||host replication repuser 0.0.0.0/0 md5|;H};}' "$PGDATA"/pg_hba.conf
    sed -i -e 's|^#wal_level.*|wal_level = hot_standby|' "$PGDATA"/postgresql.conf
    sed -i -e 's|^#max_wal_senders.*|max_wal_senders = 10|' "$PGDATA"/postgresql.conf
    sed -i -e 's|^#wal_keep_segments.*|wal_keep_segments = 50|' "$PGDATA"/postgresql.conf
    sed -i -e 's|^#wal_sender_timout.*|wal_sender_timeout = 60s|' "$PGDATA"/postgresql.conf
    sed -i -e 's|^#max_replication_slots.*|max_replication_slots = 10|' "$PGDATA"/postgresql.conf
    sed -i -e "s|^#synchronous_standby_names.*|synchronous_standby_names = '*'|" "$PGDATA"/postgresql.conf
    sed -i -e 's|^#archive_mode.*|archive_mode = on|' "$PGDATA"/postgresql.conf
    sed -i -e "s|^#archive_command.*|archive_command = 'test ! -f /mnt/server/archive/%f && cp %p /mnt/server/archive/%f'|" "$PGDATA"/postgresql.conf    
    gosu postgres psql -v ON_ERROR_STOP -c "CREATE USER repuser REPLICATION LOGIN CONNECTION LIMIT 10 PASSWORD '$POSTGRES_REPLICATION_PASSWORD';"
    gosu postgres psql -v ON_ERROR_STOP template1 -c "REVOKE ALL ON DATABASE template1 FROM public;REVOKE ALL ON SCHEMA public FROM public;GRANT ALL ON SCHEMA public TO postgres;"
fi
