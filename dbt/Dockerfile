FROM ghcr.io/dbt-labs/dbt-postgres:latest

RUN apt-get update && apt-get -y install cron

COPY requirements.txt .
RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt

# set up cron
COPY ./cron/cron_update /etc/cron.d/cron_update
RUN chmod 0644 /etc/cron.d/cron_update
RUN crontab /etc/cron.d/cron_update

# copy backup scripts
RUN mkdir -p /home/update
COPY ./cron/update.sh /home/update/.
RUN chmod 0744 /home/update/update.sh

RUN touch /var/log/cron.log

RUN ln -sf /dev/stdout /var/log/cron.log \
    && ln -sf /dev/stderr /var/log/cron.log

ENTRYPOINT []
CMD ["cron", "-f", "&&", "tail", "-f", "/var/log/cron.log"]