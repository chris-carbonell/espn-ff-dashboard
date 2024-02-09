# Dependencies
import pandas as pd
import re

# Funcs

def get_js(path_js: str):
    '''
    convert JavaScript array of dicts to a Python list of dicts
    '''
    with open(path_js, "r") as f:
        js = f.readlines()
        
    for idx, l in enumerate(js):
        js[idx] = re.sub(r"\s(\w*):", r"'\1':", js[idx])
        js[idx] = re.sub(": false", ": False", js[idx])
        js[idx] = re.sub(": true", ": True", js[idx])
        js[idx] = re.sub(": null", ": None", js[idx])
    
    js = "".join(js)
    js = eval(js)

    return js

if __name__ == "__main__":

    # loop through files
    # create df and save to CSV
    for path_js in [
        "activities.js",
        "positions.js",
        "stats.js",
        "teams.js"
    ]:
        js = get_js(path_js)
        data = pd.DataFrame.from_records(js)
        data.to_csv(path_js.replace(".js", ".csv"), index = False)