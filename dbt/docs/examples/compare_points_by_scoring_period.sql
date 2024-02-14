-- # Overview
-- compare points by scoring period

WITH

	c_totals AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_int.int_player_stats__clean

        GROUP BY 1, 2
        ORDER BY 1, 2
    )

	, d_totals AS (
		SELECT
			t.season_id
			, t.scoring_period_id
			
			, SUM(fp.points_actual) AS points_actual
			, SUM(fp.points_projected) AS points_projected
		
		FROM d_mrt.fct_points fp 
		
		LEFT JOIN d_mrt.dim_time t
		ON fp.time_key = t.time_key
		
		GROUP BY t.season_id
			, t.scoring_period_id
			
		ORDER BY t.season_id
			, t.scoring_period_id
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