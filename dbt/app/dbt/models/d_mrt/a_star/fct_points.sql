WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

	-- fct_points
	, fct_points AS (
		SELECT
			-- surrogate keys
			{{ dbt_utils.generate_surrogate_key(['team_id']) }} as team_key
			, {{ dbt_utils.generate_surrogate_key(['player_id']) }} as player_key
			, {{ dbt_utils.generate_surrogate_key(['stat']) }} as stat_key

			-- facts
			, points_projected
			, points_actual
				
		FROM hilaw
	)

	, lutu AS (
		SELECT * FROM fct_points
	)
	
SELECT * FROM lutu