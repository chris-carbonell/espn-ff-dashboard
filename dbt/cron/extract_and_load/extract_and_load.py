# Overview
# * extract and load data
# * if data already exists, use incremental load
# * otherwise, get initial load

# TODO:
# * only update data if it's different from the latest pull
# * add logging
# * try/except
#     * and want to know why it failed too
# * for production
#     * instead of mounting, use Dockerfile to copy
#         * and automate via cron in dbt container

# Dependencies

# db
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# utils
from utils.config import get_config
from utils.data import *

# constants
from constants import *

# constants
from constants import RAW_SCHEMA, EXPECTED_TABLES

if __name__ == "__main__":

    # check if tables have data

    # get config
    config_league = get_config(PATH_LEAGUE)
    cookies = get_cookies(config_league)
    connections = get_config(PATH_CONN)

    # get engine
    url = URL.create(**connections['data'])
    engine = create_engine(url)

    # check all tables
    incremental = True
    for table in EXPECTED_TABLES:
        
        # get record count 
        # I just need to know that there's at least one record
        # so I use LIMIT 1 to avoid reading the whole table
        sql = f"SELECT COUNT(*) AS cnt_records FROM (SELECT 1 FROM {RAW_SCHEMA}.{table} LIMIT 1)"
        with engine.connect() as con:
            try:
                data = con.execute(text(sql)).fetchall()
            except:
                incremental = False
                break

        # if any of them are 0, do initial load (i.e., just reload)
        records = data[0][0]  # e.g., data = [(1,)]
        if records == 0:
            incremental = False
            break

    # route
    if incremental:
        from extract_and_load_incremental import main
    else:
        from extract_and_load_initial import main

    # get data
    main()