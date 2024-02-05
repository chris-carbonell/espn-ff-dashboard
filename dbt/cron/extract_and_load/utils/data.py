# Dependencies

# general
from datetime import datetime
import json
import os

# data
import requests

# db
from sqlalchemy.sql import text

# constants
from constants import RAW_SCHEMA

# Funcs

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

def get_data(url: str, cookies: dict, **kwargs):
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

    # headers
    headers = {
        'Accept': "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        'Host': "fantasy.espn.com",
        'User-Agent': "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
    }
    
    # get res
    ts_before_request = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    res = requests.get(
        url,
        cookies = cookies,
        headers = headers,
        **kwargs
    )
    
    # prep data
    data = {
        'ts_load': ts_before_request,
        'request_url': res.url,
        'status_code': int(str(res.status_code)),
        'res': json.dumps(res.json()),
    }

    return data

def insert_data(engine, table: str, data: dict):
    '''
    insert data (from get_data) into raw table
    '''
    sql = f"""
        INSERT INTO {RAW_SCHEMA}.{table}
        ({', '.join([k for k in data.keys()])})
        VALUES ({', '.join([':' + k for k in data.keys()])})
        ;
        """
    with engine.begin() as con:
        con.execute(text(sql), data)

def update_raw(engine, view: str, season_id: str, league_id: str, cookies: dict):
    '''
    request latest data and insert
    '''

    # get res
    url = f"https://fantasy.espn.com/apis/v3/games/ffl/seasons/{season_id}/segments/0/leagues/{league_id}"
    params = {'view': view}
    data = get_data(url = url, params = params, cookies = cookies)

    # insert
    # views start with "m" so chop it off
    insert_data(engine, view[1:].lower(), data)