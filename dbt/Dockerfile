FROM python:3.12.2-slim-bookworm

RUN apt-get update && apt-get -y install cron

COPY requirements.txt .
RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt

# set up cron
COPY ./cron/cron_update /etc/cron.d/cron_update
RUN chmod 0644 /etc/cron.d/cron_update
RUN crontab /etc/cron.d/cron_update

# copy cron scripts
RUN mkdir -p /home/update
COPY ./cron/update.sh /home/update/.
RUN chmod 0744 /home/update/update.sh
COPY ./cron/extract_and_load /home/update/extract_and_load

RUN touch /var/log/cron.log

RUN ln -sf /dev/stdout /var/log/cron.log \
    && ln -sf /dev/stderr /var/log/cron.log

# set up entrypoint
# for some reason, I can't execute from /usr/app
COPY docker-entrypoint.sh /
RUN ["chmod", "+x", "/docker-entrypoint.sh"]

WORKDIR /usr/app/dbt

ENTRYPOINT ["/docker-entrypoint.sh"]