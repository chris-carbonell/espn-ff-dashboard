# Overview
* pull data from ESPN's unofficial fantasy football API
* visualize the data to demonstrate my lack of luck

# Resources
* JS API package<br>http://espn-fantasy-football-api.s3-website.us-east-2.amazonaws.com/
* python repos that pull from the API
    * `espn-api`<br>https://github.com/cwendt94/espn-api
        * stat ID mapping<br>https://github.com/cwendt94/espn-api/issues/84
    * `espnff`<br>https://github.com/rbarton65/espnff
    * useful for general layout of the API
* how to get necessary cookies<br>https://cran.r-project.org/web/packages/ffscrapr/vignettes/espn_authentication.html

# Questions
* who drafts the best?
    * for the initial set of drafted players, total all points scored
    * account for keepers? I guess not
* who plays the wire best?
    * number of wire transactions
* who manages their line ups the best?
    * points actually scored / points that could've been scored
* power rankings
    * if each team played every other team, what would their record be?

# Roadmap
* create OBT from star
    * https://docs.getdbt.com/blog/kimball-dimensional-model
* create documentation via yamls
* get logs from data.py outputting to dbt's logs? we should see f"{table}: {insert}"
* mRoster
    * playerPoolEntry.player.ownership.auctionValueAverage
    * playerPoolEntry.player.ownership.averageDraftPosition
* save data['settings']['scoringSettings']['scoringItems']
    * can we recalculate scores from the ground up? the total points are provided
    * parsing loop<br>https://github.com/cwendt94/espn-api/blob/81f6d2f8a4dbb5715041d101ae76fb0dcd9e239c/espn_api/football/settings.py#L8
    * map of statId to colloqial name<br>https://github.com/cwendt94/espn-api/blob/81f6d2f8a4dbb5715041d101ae76fb0dcd9e239c/espn_api/football/constant.py#L271
