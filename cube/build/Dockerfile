FROM cubejs/cube:latest
 
WORKDIR /usr/app

RUN apt update && apt install -y pip
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY cube.py .
COPY model model
COPY manifest.json .