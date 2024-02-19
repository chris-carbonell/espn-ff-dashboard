-- # Overview
-- compare control totals to totals with a dim join

-- # Quickstart
-- just update the `dim` and `fct` CTEs
-- and `dim_id` in the `c_points_indiv` CTE

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
	
	, c_points_indiv AS (
		SELECT
            season_id
            , scoring_period_id
            , player_id AS dim_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_int.int_player_stats__clean
        
        GROUP BY season_id
        	, scoring_period_id
        	, dim_id
	)

	, c_totals AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_points_indiv
        
        GROUP BY season_id
        	, scoring_period_id
    )

	, d_points_indiv AS (
		SELECT
			g.season_id
			, g.scoring_period_id
			
			, dim.dim_key
			, dim.dim_id
			
			, SUM(fp.points_actual) AS points_actual
			, SUM(fp.points_projected) AS points_projected
		
		FROM fct fp
		
		LEFT JOIN d_mrt.dim_games g
		ON fp.game_key = g.game_key
		
		LEFT JOIN dim
		ON fp.dim_key = dim.dim_key
		
		-- if the keys don't match (e.g., didn't update the input CTEs correctly)
		-- I want the totals to show a mismatch
		-- if we didn't have this WHERE clause, the totals would match exactly
		-- eventhough none of the keys matched
		WHERE dim.dim_key IS NOT NULL
		
		GROUP BY g.season_id
			, g.scoring_period_id
			, dim.dim_key
			, dim.dim_id
			
		ORDER BY g.season_id
			, g.scoring_period_id
			, dim.dim_key
			, dim.dim_id
	)

	, d_points AS (
		SELECT
			season_id
			, scoring_period_id
			
			, dim_id
			
			, SUM(points_actual) AS points_actual
			, SUM(points_projected) AS points_projected
		
		FROM d_points_indiv
		
		GROUP BY season_id
			, scoring_period_id
			, dim_id
			
		ORDER BY season_id
			, scoring_period_id
			, dim_id
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
	
	, missing_from_dim AS (
		SELECT
			COALESCE(c.season_id, d.season_id) AS season_id
			, COALESCE(c.scoring_period_id, d.scoring_period_id) AS scoring_period_id
			
			, d.dim_key
			, COALESCE(c.dim_id, d.dim_id) AS dim_id
			
			-- control
			, c.points_actual AS c_points_actual
			, c.points_projected AS c_points_projected
			
			-- test
			, d.points_actual AS d_points_actual
			, d.points_projected AS d_points_projected
			
			-- difference
			, d.points_actual - c.points_actual AS diff_points_actual
			, d.points_projected - c.points_projected AS diff_points_projected
		
		FROM c_points_indiv c
		
		FULL OUTER JOIN d_points_indiv d
		ON c.dim_id = d.dim_id
			AND c.season_id = d.season_id
			AND c.scoring_period_id = d.scoring_period_id
			
		WHERE c.season_id IS NULL
			OR c.scoring_period_id IS NULL
			OR c.dim_id IS NULL
	)
	
--SELECT * FROM comparison
	
SELECT
	*
FROM d_mrt.dim_players
WHERE player_key IN (SELECT dim_key FROM missing_from_dim)