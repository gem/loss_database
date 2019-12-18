#!/bin/sh

. $(readlink -f $(dirname $0))/db_settings.sh

createdb -U $DB_USER -p $DB_PORT -h $DB_HOST $DB_NAME

psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME  << _EOF_
CREATE EXTENSION postgis;
CREATE ROLE lossusers NOLOGIN NOINHERIT;
CREATE ROLE lossviewer NOLOGIN INHERIT;
CREATE ROLE losscontrib NOLOGIN INHERIT;
GRANT lossusers TO lossviewer;
GRANT lossviewer TO losscontrib;
_EOF_

echo "$0: Don't forget to set passwords for lossviewer and losscontrib" >&2
