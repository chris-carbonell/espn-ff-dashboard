# Known Issues

## 2022
* scoring_period_id = 17
    * Damar Hamlin collapse
        * the game was cancelled (game_id = 401437947)
        * projected points exist for that game but no actual points were recorded
        * since no game_id exists in the player stats data
            * those projected points (114.63) do not get mapped to a season_id or a scoring_period_id

## 2021
* scoring_period_id = 16
    * Jonnu Smith missing actual points so there's no corresponding game_id