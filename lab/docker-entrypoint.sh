#!/usr/bin/env bash

# generate config
jupyter notebook --generate-config
# HASHED_PASSWORD=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${LAB_PASSWORD}'))" | sed 's/\$/\\\$/g')
HASHED_PASSWORD=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('${LAB_PASSWORD}'))")
echo "c.NotebookApp.password='${HASHED_PASSWORD}'" >> /root/.jupyter/jupyter_notebook_config.py

# launch jupyter lab in venv
source /opt/venv/bin/activate
jupyter lab --ip=0.0.0.0 --allow-root --ServerApp.allow_origin=* --ServerApp.open_browser=False