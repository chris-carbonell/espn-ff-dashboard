#!/usr/bin/env bash

# dbt
(cd /usr/app & dbt deps)

# cron
cron -f && tail -f /var/log/cron.log