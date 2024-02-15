#!/usr/bin/env bash

# dbt
(cd /usr/app & dbt deps & dbt seed)

# cron
cron -f && tail -f /var/log/cron.log