# Overview
# build env

FROM python:bookworm

EXPOSE 8888

RUN apt update \
    && apt install -y cmake gcc libpq-dev python3.11 python3.11-venv python3.11-dev

WORKDIR /usr/app

RUN python3.11 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN python3.11 -m pip install --upgrade pip \
    && python3.11 -m pip install -r requirements.txt

# set up entrypoint
# for some reason, I can't execute from /usr/app
COPY docker-entrypoint.sh /
RUN ["chmod", "+x", "/docker-entrypoint.sh"]

ENTRYPOINT ["/docker-entrypoint.sh"]