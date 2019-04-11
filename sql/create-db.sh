#!/bin/sh
DB_NAME=loss

createdb $DB_NAME

psql -d $DB_NAME -c "CREATE EXTENSION postgis;"
psql -d $DB_NAME -f common.sql
psql -d $DB_NAME -f loss_schema.sql
