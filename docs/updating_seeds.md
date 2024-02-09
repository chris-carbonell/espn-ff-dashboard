# Overview
we grabbed the seeds from the JavaScript from the league settings page

# How?
1. navigate to the league settings:<br>
https://fantasy.espn.com/football/league/settings?leagueId=22557595&view=scoring
1. view the source code
1. search for `/commons/main` and nvaigate to the resulting link for that JavaScript
* for the 2023-24 season, it lead me here:<br>
http://cdn1.espn.net/kona/2a092d14f6f3-1.80/_next/static/commons/main-569c140b77690c76794e.js
1. beautify the JavaScript with https://beautifier.io/
* it's minified (so all the code is on one giant line) 

# Why?
* there's a TON of great data in there (e.g., stat ID mapping)
    * line 158255 has all the mappings for stats (e.g., stat ID and abbrev and description)
    * line 157625 has team abbrevs, location, and name
    * line 157461 has positions

# Resources
* https://github.com/cwendt94/espn-api/issues/84

# Next Stesp
* could this be automated? bc I bet this changes