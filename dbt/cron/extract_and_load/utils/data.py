# Dependencies

# general
from datetime import datetime
import json
import logging
import os

# data
import requests

# db
from sqlalchemy.sql import text

# constants
from constants import RAW_SCHEMA

# Set Up

logger = logging.getLogger(__name__)

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
        'res': json.dumps(res.json(), sort_keys = True),
    }

    return data

def get_latest_data(engine, table: str):
    '''
    get latest data by timestamp
    '''
    sql = f"""
        SELECT 
            res
        FROM {RAW_SCHEMA}.{table}
        ORDER BY ts_load DESC
        LIMIT 1
        ;
        """
    with engine.connect() as con:
        try:
            data = con.execute(text(sql)).fetchall()
            return data[0][0]  # e.g., data = [({'a': 1},)]
        except:
            return None

def compare_dicts(d1, d2, keys=["$"]):
    '''
    compare two dicts
    ignore the order of lists (just make sure each element in each list is present in the other)

    the API returns lists of dicts sometimes
    and the order varies between requests
    but the content is often the same
    '''

    def _equal_ignore_order(a, b):
        '''
        compare lists of objects that are neither hashable nor sortable (e.g., dicts)
        https://stackoverflow.com/questions/8866652/determine-if-2-lists-have-the-same-elements-regardless-of-order
        '''

        # check lengths
        if len(a) != len(b):
            logger.error(f"different lengths: {len(a)} != {len(b)}")
            return False

        # check each element
        unmatched = list(b)
        for element in a:
            try:
                unmatched.remove(element)
            except ValueError:
                logger.error(f"element not found: {element}")
                return False
        return not unmatched

    # check keys
    if d1.keys() != d2.keys():
        logger.error(f"keys don't match: {keys}")
        return False

    # check for empty dicts
    if d1 == {} and d2 == {}:
        return True

    same = None
    for k, v in d1.items():
        if isinstance(v, list):
            # compare lists
            same = _equal_ignore_order(v, d2[k])
            if not same:
                logger.error(f"lists different:\n{keys + [k]}")
        elif isinstance(v, dict):
            # recurse
            same = compare_dicts(v, d2[k], keys + [k])
            if not same:
                logger.error(f"compare dicts failed:\n{keys + [k]}")
        else:
            same = v == d2[k]
            if not same:
                logger.error(f"scalars don't match:\n{keys + [k]}\n{v}\nvs.\n{d2[k]}")

        # check for early stop
        if not same:
            return False

    return same

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
    request latest data and insert if new
    '''

    # parse
    table = view[1:].lower()  # views start with "m" so chop it off

    # get res
    url = f"https://fantasy.espn.com/apis/v3/games/ffl/seasons/{season_id}/segments/0/leagues/{league_id}"
    params = {'view': view}
    data = get_data(url = url, params = params, cookies = cookies)

    # get latest data
    data_latest = get_latest_data(engine, table)

    # determine if insert necessary
    insert = False
    if data_latest:
        # insert = data_latest != json.loads(data['res'])
        # insert = not compare_dicts(data_latest, json.loads(data['res']))
        insert = not compare_dicts(data_latest, data_latest)
    else:
        # no data so insert
        insert = True

    logger.debug(f"{table}: {insert}")

    insert
    if insert:
        insert_data(engine, table, data)