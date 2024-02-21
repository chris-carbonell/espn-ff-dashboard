# Dependencies

# general
from jinja2 import Template
import os
import yaml

# Funcs

def get_config(path_config: str, **kwargs):
    '''
    load yaml and replace vars if necessary
    '''

    # get template
    with open(path_config) as f:
        template = Template(f.read())
    
    # render with kwargs
    config = template.render(**kwargs)

    # expand env vars
    config = os.path.expandvars(config)
    
    return yaml.safe_load(config)