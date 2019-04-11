#!/bin/sh
DB_NAME=loss

createdb $DB_NAME

psql -d $DB_NAME << _EOF_
CREATE EXTENSION postgis;
CREATE ROLE lossusers NOLOGIN NOINHERIT;
CREATE ROLE lossviewer NOLOGIN INHERIT;
CREATE ROLE losscontrib NOLOGIN INHERIT;
GRANT lossusers TO lossviewer;
GRANT lossviewer TO losscontrib;
_EOF_

echo "$0: Don't forget to set passwords for lossviewer and losscontrib" >&2
