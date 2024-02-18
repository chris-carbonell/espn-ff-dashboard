# Overview
# * extract data from API
# * load into db

# Dependencies

# general
import logging
import sys

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

# Set Up

# logging
logging.basicConfig(level=logging.DEBUG)
logging.getLogger("requests").setLevel(logging.WARNING)
logger = logging.getLogger(__name__)

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

        # get config for requests
        # items like scoring_period_id will get rendered as None here
        # but they're not used for these season-level requests
        config_requests = get_config(PATH_REQUESTS, league_id = league_id, season_id = season_id)

        # scrape by season
        for request_details in config_requests['requests']['by_season']:
            update_raw(
                engine = engine, 
                table = request_details['table'], 
                url = request_details['url'],
                params = request_details['params'],
                cookies = cookies, 
                )

        # get number of scoring periods
        # in 2020, we only had 16 (after that, we had 17)
        url = f"https://fantasy.espn.com/apis/v3/games/ffl/seasons/{season_id}/segments/0/leagues/{league_id}"
        params = {'view': "mSettings"}
        res = get_data(url, cookies, params = params).json()
        final_scoring_period = int(res['status']['finalScoringPeriod'])

        # scrape by scoring period
        for scoring_period_id in list(range(1, final_scoring_period + 1)):

            # get config for requests
            config_requests = get_config(
                PATH_REQUESTS, 
                league_id = league_id, 
                season_id = season_id, 
                scoring_period_id = scoring_period_id
                )

            # get data
            for request_details in config_requests['requests']['by_scoring_period']:
                update_raw(
                    engine = engine, 
                    table = request_details['table'], 
                    url = request_details['url'],
                    params = request_details['params'],
                    cookies = cookies, 
                    )

if __name__ == "__main__":
    main()