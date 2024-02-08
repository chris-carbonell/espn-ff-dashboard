WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['player_stats_id']) }} as player_stat_key
            , player_stats_id
            , {{ dbt_utils.generate_surrogate_key(['player_id']) }} as player_key
        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu