#!/usr/bin/env bash

UPDATE=false
if $UPDATE ; then
    dbt run
fi