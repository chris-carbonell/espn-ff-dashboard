SELECT
	t.season_id
	-- , t.scoring_period_id
	
	, tm.team_id
	
	, mem.member_first_name || ' ' || mem.member_last_name AS member_name
	, mem.member_id
	
	, COUNT(*) AS cnt_records

FROM d_mrt.fct_points fp

LEFT JOIN d_mrt.dim_time t
ON fp.time_key = t.time_key

LEFT JOIN d_mrt.dim_members mem
ON fp.member_key = mem.member_key

LEFT JOIN d_mrt.dim_teams tm
ON fp.team_key = tm.team_key

--WHERE team_id = 1

GROUP BY 
	t.season_id
	--, t.scoring_period_id
	, tm.team_id
	, member_name
	, mem.member_id

ORDER BY
	tm.team_id
	, member_name
	, t.season_id
	-- , t.scoring_period_id