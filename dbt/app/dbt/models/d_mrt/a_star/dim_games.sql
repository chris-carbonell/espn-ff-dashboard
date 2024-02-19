WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_games__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['game_id']) }} as game_key
            
            , game_id
            , season_id
            , scoring_period_id

            , ts_game

            , pro_team_id_home
            , pro_team_id_away
            
            , game_dow
            , game_hour
            , game_tod

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu