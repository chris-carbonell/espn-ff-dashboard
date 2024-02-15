SELECT
	t.season_id
	, t.scoring_period_id
	
	, tm.team_id
	
	, SUM(fp.points_actual) AS points_actual
	, SUM(fp.points_projected) AS points_projected

FROM d_mrt.fct_points fp

LEFT JOIN d_mrt.dim_time t
ON fp.time_key = t.time_key

LEFT JOIN d_mrt.dim_teams tm
ON fp.team_key = tm.team_key

LEFT JOIN d_mrt.dim_players dp
ON fp.player_key = dp.player_key

WHERE dp.is_starter = 1
    -- AND t.season_id = 2023
    -- AND t.scoring_period_id = 7

GROUP BY t.season_id
	, t.scoring_period_id
	, tm.team_id
	, dp.is_starter
	
ORDER BY t.season_id
	, t.scoring_period_id
	, tm.team_id
	, dp.is_starter