# Overview
# * extract data from API
# * load into db

# Dependencies

# data
import requests

# db
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# utils
from utils.config import get_config
from utils.data import *

# constants
from constants import *

# Funcs

def main():
    
    # get config
    config_league = get_config(PATH_LEAGUE)
    cookies = get_cookies(config_league)
    connections = get_config(PATH_CONN)

    # get engine
    url = URL.create(**connections['data'])
    engine = create_engine(url)

    # get current season ID
    url = "https://fantasy.espn.com/apis/v3/games/ffl/seasons"
    res = requests.get(url, cookies = cookies)
    season_id = res.json()[0]['id']

    # update raw
    league_id = config_league['league']['league_id']
    for view in ["mTeam", "mRoster", "mMatchup", "mSettings", "mStandings"]:
        update_raw(engine, view, season_id, league_id, cookies)

if __name__ == "__main__":
    main()