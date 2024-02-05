# Dependencies

# general
import os
import yaml

# Funcs

def get_config(path_config: str):
    '''
    load yaml and replace env vars if necessary
    '''
    with open(path_config, "r") as f:
        return yaml.safe_load(os.path.expandvars(f.read()))