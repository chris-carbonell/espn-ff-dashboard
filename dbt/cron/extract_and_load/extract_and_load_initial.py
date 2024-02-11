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
    season_id = res.json()[0]['id']  # 0th index provides the current season's ID

    # get all seasons for the league
    league_id = config_league['league']['league_id']
    url = f"https://fantasy.espn.com/apis/v3/games/ffl/seasons/{season_id}/segments/0/leagues/{league_id}"
    params = {'view': "mTeam"}
    res = requests.get(url, params = params, cookies = cookies)
    season_ids = res.json()['status']['previousSeasons']  # start with prior seasons
    season_ids.append(season_id)  # append current season ID

    # update raw
    for season_id in season_ids:
        for scoring_period in scoring_periods:
            for view in ["mTeam", "mRoster", "mMatchup", "mSettings", "mStandings"]:
                update_raw(engine, cookies, league_id, season_id, scoring_period, view)

if __name__ == "__main__":
    main()