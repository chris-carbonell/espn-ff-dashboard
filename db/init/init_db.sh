#!/usr/bin/env bash

# constants
TODAY=$(date +"%Y-%m-%d")

# set up
set -e

# Funcs

# execute psql
# $1 = sql string
function execute {
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    $1 
EOSQL
}

# create table for specific view from API
function create_table_for_view {
    execute """
        CREATE TABLE IF NOT EXISTS a_raw.${1} (
            ${1}_id SERIAL,
            ts_load TIMESTAMP,
            request_url VARCHAR,
            status_code INT,
            res JSONB,
            PRIMARY KEY (${1}_id, ts_load)
        )
        """
}

# create raw schema
execute "CREATE SCHEMA a_raw"

# create tables for views
declare -a views=("team" "roster" "matchup" "settings" "standings")
for i in "${views[@]}"
do
   create_table_for_view "$i"
done