-- # Overview
-- calculate power rankings for the set of current owners

-- # Notes
-- * power rankings are based on the win percentage of round robin games
--     * i.e., each team plays every other team each week
-- * I chose win percentage because members can join at different times throughout the seasons
--     * so, for example, total wins would be biased towards members that have been in the league longer

WITH

	-- current_scoring_period
	-- get latest scoring period
	-- to identify current owners
	current_scoring_period AS (
		SELECT
			time_key
			, season_id
			, scoring_period_id
		FROM d_mrt.dim_times
		ORDER BY season_id DESC, scoring_period_id DESC
		LIMIT 1
	)

	-- current_owners 
	-- members that played in the latest scoring period
	, current_owners AS (
		SELECT DISTINCT
			t.season_id
			, t.scoring_period_id
			, mem.member_id
			, mem.member_first_name || ' ' || mem.member_last_name AS member_name
			, tm.team_name
		
		FROM d_mrt.fct_points fp

		LEFT JOIN d_mrt.dim_times t
		ON fp.time_key = t.time_key
		
		LEFT JOIN d_mrt.dim_members mem
		ON fp.member_key = mem.member_key
		
		LEFT JOIN d_mrt.dim_teams tm
		ON fp.team_key = tm.team_key
		
		WHERE fp.time_key = (SELECT time_key FROM current_scoring_period)
	)
	
	-- power_ranks_sp
	-- power rank stats by scoring period
	-- so we can easily roll up
	, power_ranks_sp AS (
		SELECT
			t.season_id
			, t.scoring_period_id
			
			, co.member_name
			, co.team_name
			
			, m.power_rank_team_wins
			, m.power_rank_team_losses
			, m.power_rank_team_ties
			, m.power_rank_win_pct
			
			, SUM(fp.points_actual) AS points_actual
		
		FROM d_mrt.fct_points fp 
		
		LEFT JOIN d_mrt.dim_times t
		ON fp.time_key = t.time_key
		
		LEFT JOIN d_mrt.dim_matchups m
		ON fp.matchup_key = m.matchup_key
		
		LEFT JOIN d_mrt.dim_players dp
		ON fp.player_key = dp.player_key
				
		LEFT JOIN d_mrt.dim_members mem
		ON fp.member_key = mem.member_key
		
		LEFT JOIN current_owners co
		ON mem.member_id = co.member_id
		
		WHERE dp.is_starter = 1
			AND co.member_id IS NOT NULL
		
		GROUP BY
			t.season_id
			, t.scoring_period_id
			, co.member_name
			, co.team_name
			, m.power_rank_team_wins
			, m.power_rank_team_losses
			, m.power_rank_team_ties
			, m.power_rank_win_pct
			
		ORDER BY
			t.season_id
			, t.scoring_period_id
			, m.power_rank_win_pct DESC
	)
	
	-- power_ranks_all_time
	-- power ranks all time
	, power_ranks_all_time AS (
		SELECT
			*
			, RANK() OVER(ORDER BY win_pct DESC, points_actual DESC) AS power_ranking
		FROM (
			SELECT
				member_name
				, team_name
				
				, SUM(power_rank_team_wins) AS power_rank_team_wins	
				, SUM(power_rank_team_losses) AS power_rank_team_losses
				, SUM(power_rank_team_ties) AS power_rank_team_ties
				
				, SUM(points_actual) AS points_actual
				
				, ROUND((SUM(power_rank_team_wins) + 0.5 * SUM(power_rank_team_ties)) / (SUM(power_rank_team_wins) + SUM(power_rank_team_losses) + SUM(power_rank_team_ties))::NUMERIC, 3) AS win_pct
			
			FROM power_ranks_sp
			
			GROUP BY
				member_name
				, team_name
		) t
	)
	
	, lutu AS (
		SELECT * FROM power_ranks_all_time pr
	)
	
SELECT * FROM lutu