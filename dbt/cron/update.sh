#!/usr/bin/env bash

# constants
UPDATE=true

# update
if $UPDATE ; then
    # update data
    python /home/update/extract_and_load/extract_and_load.py

    # dbt
    dbt run
fi