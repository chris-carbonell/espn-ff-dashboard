-- # Overview
-- compare control totals to totals with a dim join

-- # Quickstart
-- just update the `dim` and `fct` CTEs

WITH

    -- dim
	-- alias dim-specific fields
	-- so the d_points CTE doesn't have to change
	dim AS (
    	SELECT
    		player_key AS dim_key
    		, player_id AS dim_id
    	FROM d_mrt.dim_players
    )

	-- fct
	-- alias dim key
	-- so the d_points CTE doesn't have to change
	, fct AS (
		SELECT
			player_key AS dim_key
			, *
		FROM d_mrt.fct_points fp
	)

	, c_totals AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_int.int_player_stats__clean

        GROUP BY 1, 2
        ORDER BY 1, 2
    )

	, d_points AS (
		SELECT
			t.season_id
			, t.scoring_period_id
			
			, dim.dim_id
			
			, SUM(fp.points_actual) AS points_actual
			, SUM(fp.points_projected) AS points_projected
		
		FROM fct fp
		
		LEFT JOIN d_mrt.dim_time t
		ON fp.time_key = t.time_key
		
		LEFT JOIN dim
		ON fp.dim_key = dim.dim_key
		
		-- if the keys don't match (e.g., didn't update the input CTEs correctly)
		-- I want the totals to show a mismatch
		-- if we didn't have this WHERE clause, the totals would match exactly
		-- eventhough none of the keys matched
		WHERE dim.dim_key IS NOT NULL
		
		GROUP BY t.season_id
			, t.scoring_period_id
			, dim.dim_id
			
		ORDER BY t.season_id
			, t.scoring_period_id
			, dim.dim_id
	)
	
	, d_totals AS (
		SELECT
			season_id
			, scoring_period_id
			
			, SUM(points_actual) AS points_actual
			, SUM(points_projected) AS points_projected
			
		FROM d_points
		
		GROUP BY season_id
			, scoring_period_id
			
		ORDER BY season_id
			, scoring_period_id
	)
	
	, comparison AS (
		SELECT
			COALESCE(c.season_id, d.season_id) AS season_id
			, COALESCE(c.scoring_period_id, d.scoring_period_id) AS scoring_period_id
			
			-- control
			, c.points_actual AS c_points_actual
			, c.points_projected AS c_points_projected
			
			-- test
			, d.points_actual AS d_points_actual
			, d.points_projected AS d_points_projected
			
			-- difference
			, d.points_actual - c.points_actual AS diff_points_actual
			, d.points_projected - c.points_projected AS diff_points_projected
		
		FROM c_totals c
		
		FULL OUTER JOIN d_totals d
		ON c.season_id = d.season_id
			AND c.scoring_period_id = d.scoring_period_id
	)
	
SELECT * FROM comparison