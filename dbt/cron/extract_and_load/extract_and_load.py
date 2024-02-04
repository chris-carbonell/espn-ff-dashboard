# Overview
# * extract data from API
# * load into db

# TODO:
# * add logging
# * try/except (I want to see 400s in a_raw even if no data pulled)
#     * and want to know why it failed too
# * for production
#     * pull the season ID from some endpoint for the current
#     * instead of mounting, use Dockerfile to copy
#         * and automate via cron in dbt container

# Dependencies

# general
from datetime import datetime
import json
import os
import yaml

# data
import requests

# db
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.sql import text

# Constants

PATH_CONN = "./config/connections.yml"
PATH_LEAGUE = "./config/league.yml"

# Funcs

def get_config(path_config: str):
    '''
    load yaml and replace env vars if necessary
    '''
    with open(path_config, "r") as f:
        return yaml.safe_load(os.path.expandvars(f.read()))

def get_cookies(config: str | dict):
    '''
    get cookies for requests
    '''

    # parse args
    if isinstance(config, dict):
        pass
    elif isinstance(config, str):
        # get config
        config = get_config(path_config)
    else:
        raise AttributeError("one of config or path_config must be specified")
    
    # fix swid
    config['league']['swid'] = os.environ['swid']

    return {
        'espn_s2': config['league']['espn_s2'],
        'SWID': config['league']['swid'],
    }

def get_data(url: str, **kwargs):
    '''
    get response from API and prepare for insert

    # Example
    ```
    cookies = get_cookies()
    url = "https://fantasy.espn.com/apis/v3/games/ffl/seasons/2023/segments/0/leagues/22557595"
    params = {'view': ['mTeam', 'mRoster', 'mMatchup', 'mSettings', 'mStandings']}
    data = get_data(
        url,
        params = params,
    )
    ```
    '''
    
    # get res
    ts_before_request = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    res = requests.get(
        url,
        **kwargs,
        cookies = cookies
    )
    
    # prep data
    data = {
        'ts_load': ts_before_request,
        'request_url': res.url,
        'status_code': int(str(res.status_code)),
        'res': json.dumps(res.json()),
    }

    return data

def insert_data(table: str, data: dict):
    '''
    insert data (from get_data) into raw table
    '''
    schema = "a_raw"
    sql = f"""
        INSERT INTO {schema}.{table}
        ({', '.join([k for k in data.keys()])})
        VALUES ({', '.join([':' + k for k in data.keys()])})
        ;
        """
    with engine.begin() as con:
        con.execute(text(sql), data)

def update_raw(view: str, season_id: str, league_id: str):
    '''
    request latest data and insert
    '''

    # get res
    url = f"https://fantasy.espn.com/apis/v3/games/ffl/seasons/{season_id}/segments/0/leagues/{league_id}"
    params = {'view': view}
    data = get_data(url = url, params = params)

    # insert
    # views start with "m" so chop it off
    insert_data(view[1:].lower(), data)

if __name__ == "__main__":

    # get config
    config_league = get_config(PATH_LEAGUE)
    cookies = get_cookies(config_league)
    connections = get_config(PATH_CONN)

    # get engine
    url = URL.create(**connections['data'])
    engine = create_engine(url)

    # update raw
    season_id = "2023"  # TODO: get the latest from the api?
    league_id = config_league['league']['league_id']
    for view in ["mTeam", "mRoster", "mMatchup", "mSettings", "mStandings"]:
        update_raw(view, season_id, league_id)