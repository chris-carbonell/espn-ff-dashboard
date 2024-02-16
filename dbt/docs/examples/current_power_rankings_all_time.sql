WITH

	-- current_scoring_period
	-- get latest scoring period
	-- to identify current owners
	current_scoring_period AS (
		SELECT
			time_key
			, season_id
			, scoring_period_id
		FROM d_mrt.dim_time
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

		LEFT JOIN d_mrt.dim_time t
		ON fp.time_key = t.time_key
		
		LEFT JOIN d_mrt.dim_members mem
		ON fp.member_key = mem.member_key
		
		LEFT JOIN d_mrt.dim_teams tm
		ON fp.team_key = tm.team_key
		
		WHERE fp.time_key = (SELECT time_key FROM current_scoring_period)
	)
	
	-- stats_scoring_period
	-- power rank stats by scoring period
	-- so we can easily roll up
	, stats_scoring_period AS (
		SELECT
			t.season_id
			, t.scoring_period_id
			
			, co.member_name
			, co.team_name

			-- actual
			, m.team_won
			, m.team_lost
			, m.team_tied
			
			-- power rank
			, m.power_rank_team_wins
			, m.power_rank_team_losses
			, m.power_rank_team_ties
			, m.power_rank_win_pct
			
			, SUM(fp.points_actual) AS points_actual
		
		FROM d_mrt.fct_points fp 
		
		LEFT JOIN d_mrt.dim_time t
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
			, m.team_won
			, m.team_lost
			, m.team_tied
			, m.power_rank_team_wins
			, m.power_rank_team_losses
			, m.power_rank_team_ties
			, m.power_rank_win_pct
			
		ORDER BY
			t.season_id
			, t.scoring_period_id
			, m.power_rank_win_pct DESC
	)
	
	-- stats_all_time
	, stats_all_time AS (
		SELECT
			*
			, RANK() OVER(ORDER BY power_rank_win_pct DESC, points_actual DESC) AS power_ranking
		FROM (
			SELECT
				member_name
				, team_name
				
				-- actual
				
				, ROUND(SUM(points_actual)::NUMERIC, 0) AS points_actual

				-- , SUM(m.team_won) AS team_wins
				-- , SUM(m.team_lost) AS team_losses
				-- , SUM(m.team_tied) AS team_ties
				, SUM(team_won) || '-' || SUM(team_lost) || '-' || SUM(team_tied) AS actual_win_loss
				, 100 * ROUND((SUM(team_won) + 0.5 * SUM(team_tied)) / (SUM(team_won) + SUM(team_lost) + SUM(team_tied))::NUMERIC, 2) AS actual_win_pct

				-- power rankings
				
				-- , SUM(power_rank_team_wins) AS power_rank_team_wins	
				-- , SUM(power_rank_team_losses) AS power_rank_team_losses
				-- , SUM(power_rank_team_ties) AS power_rank_team_ties
				, SUM(power_rank_team_wins) || '-' || SUM(power_rank_team_losses) || '-' || SUM(power_rank_team_ties) AS power_rank_win_loss
				, 100 * ROUND((SUM(power_rank_team_wins) + 0.5 * SUM(power_rank_team_ties)) / (SUM(power_rank_team_wins) + SUM(power_rank_team_losses) + SUM(power_rank_team_ties))::NUMERIC, 2) AS power_rank_win_pct
			
			FROM stats_scoring_period
			
			GROUP BY
				member_name
				, team_name
		) t
	)
	
	, stats_all_time_luck AS (
		SELECT
			*
			, 100 * ROUND(((actual_win_pct - power_rank_win_pct + 100) / 200)::NUMERIC, 2) AS luck 
		FROM stats_all_time
	)
	
	, lutu AS (
		SELECT * FROM stats_all_time_luck
	)
	
SELECT * FROM lutu