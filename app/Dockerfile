FROM python:3.12.2-slim-bookworm

WORKDIR /usr/app

COPY ./app/requirements.txt .
RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir --upgrade -r requirements.txt

COPY ./app/main.py .

CMD ["gunicorn", "main:server", "-b", "0.0.0.0:80"]