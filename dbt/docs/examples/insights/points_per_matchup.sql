SELECT
	t.season_id
	, t.scoring_period_id
	
	, m.team_id
	, m.opponent_team_id
	
	, SUM(fp.points_actual) AS points_actual

FROM d_mrt.fct_points fp 

LEFT JOIN d_mrt.dim_times t
ON fp.time_key = t.time_key

LEFT JOIN d_mrt.dim_matchups m
ON fp.matchup_key = m.matchup_key

LEFT JOIN d_mrt.dim_players dp
ON fp.player_key = dp.player_key

WHERE dp.is_starter = 1

GROUP BY
	t.season_id
	, t.scoring_period_id
	, m.team_id
	, m.opponent_team_id
	
ORDER BY
	t.season_id
	, t.scoring_period_id
	, m.team_id
	, m.opponent_team_id