WITH

    hilaw AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

    -- dims

	, dim_player_stats AS (
		SELECT * FROM {{ ref('dim_player_stats') }}
	)

    , dim_players AS (
		SELECT * FROM {{ ref('dim_players') }}
	)

    , dim_stats AS (
		SELECT * FROM {{ ref('dim_stats') }}
	)

    -- fct_points
    , fct_points AS (
        SELECT DISTINCT
            -- {{ dbt_utils.generate_surrogate_key(['player_stats_id']) }} as player_stats_key
            {{ dbt_utils.generate_surrogate_key(['player_id']) }} as player_key
            , {{ dbt_utils.generate_surrogate_key(['stat']) }} as stat_key
            , points_scored
        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM fct_points
	)
	
SELECT * FROM lutu