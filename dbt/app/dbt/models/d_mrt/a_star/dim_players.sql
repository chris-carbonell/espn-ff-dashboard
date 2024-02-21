WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['game_id', 'player_id']) }} as player_key

            , season_id
            , scoring_period_id
            , game_id
            , player_id
            
            , player_full_name

            , position_name
			, position_abbrev

			, is_starter
			, is_on_bench
			, is_on_ir

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu