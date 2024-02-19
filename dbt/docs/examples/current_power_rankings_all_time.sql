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
			, m.team_points
			, m.opponent_points
		
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
		
		WHERE is_regular_season = 1
			AND dp.is_starter = 1
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
			, m.team_points
			, m.opponent_points
			
		ORDER BY
			t.season_id
			, t.scoring_period_id
			, m.power_rank_win_pct DESC
	)
	
	-- stats_all_time
	, stats_all_time AS (
		SELECT
			*
			, RANK() OVER(ORDER BY power_rank_win_pct DESC, points_for DESC) AS power_ranking
		FROM (
			SELECT
				member_name
				, team_name
				
				-- actual
				
				-- , ROUND(SUM(points_actual)::NUMERIC, 0) AS points_actual  -- this matches points_for
				, ROUND(SUM(team_points)::NUMERIC, 0) AS points_for
				, ROUND(SUM(opponent_points)::NUMERIC, 0) AS points_against

				 , SUM(team_won) AS team_wins
				 , SUM(team_lost) AS team_losses
				 , SUM(team_tied) AS team_ties
				, SUM(team_won) || '-' || SUM(team_lost) || '-' || SUM(team_tied) AS actual_win_loss
				-- , 100 * ROUND((SUM(team_won) + 0.5 * SUM(team_tied)) / (SUM(team_won) + SUM(team_lost) + SUM(team_tied))::NUMERIC, 2) AS actual_win_pct
				, (SUM(team_won) + 0.5 * SUM(team_tied)) / (SUM(team_won) + SUM(team_lost) + SUM(team_tied)) AS actual_win_pct

				-- power rankings
				
				 , SUM(power_rank_team_wins) AS power_rank_team_wins	
				 , SUM(power_rank_team_losses) AS power_rank_team_losses
				 , SUM(power_rank_team_ties) AS power_rank_team_ties
				, SUM(power_rank_team_wins) || '-' || SUM(power_rank_team_losses) || '-' || SUM(power_rank_team_ties) AS power_rank_win_loss
				-- , 100 * ROUND((SUM(power_rank_team_wins) + 0.5 * SUM(power_rank_team_ties)) / (SUM(power_rank_team_wins) + SUM(power_rank_team_losses) + SUM(power_rank_team_ties))::NUMERIC, 2) AS power_rank_win_pct
				, (SUM(power_rank_team_wins) + 0.5 * SUM(power_rank_team_ties)) / (SUM(power_rank_team_wins) + SUM(power_rank_team_losses) + SUM(power_rank_team_ties)) AS power_rank_win_pct
			
			FROM stats_scoring_period
			
			GROUP BY
				member_name
				, team_name
		) t
	)
	
	, stats_all_time_luck_p AS (
		SELECT
			*
			-- luck
			-- luck < 0: not lucky
			-- luck > 0: lucky
			-- luck = 0: neither lucky nor unlucky
			, 100 * ROUND(((actual_win_pct - power_rank_win_pct) / 200)::NUMERIC, 2) AS luck_simple
			
			, (actual_win_pct * (team_wins + team_losses + team_ties) + power_rank_win_pct * (power_rank_team_wins + power_rank_team_losses + power_rank_team_ties)) / (team_wins + team_losses + team_ties + power_rank_team_wins + power_rank_team_losses + power_rank_team_ties) AS p
			, team_wins + team_losses + team_ties AS n_actual
			, power_rank_team_wins + power_rank_team_losses + power_rank_team_ties AS n_power_rank
			
		FROM stats_all_time
	)
	
	, stats_all_time_luck_se AS (
		SELECT
			*
						
			, SQRT(p * (1 - p) * ((1 / n_actual) + (1 / n_power_rank))) AS se
			
		FROM stats_all_time_luck_p
	)
	
	, stats_all_time_luck_z AS (
		SELECT
			*
						
			-- , (actual_win_pct - power_rank_win_pct) / se AS z
			, (actual_win_pct - power_rank_win_pct) / se AS luck
			
		FROM stats_all_time_luck_se
	)
	
	, stats_all_time_luck AS (
		SELECT
			member_name
			, team_name
			, points_for
			, points_against

			, actual_win_loss
			, ROUND(actual_win_pct::NUMERIC, 2) AS actual_win_pct

			, power_rank_win_loss
			, ROUND(power_rank_win_pct::NUMERIC, 2) AS power_rank_win_pct
			
			, power_ranking

			, ROUND(luck::NUMERIC, 1) AS luck
			
		FROM stats_all_time_luck_z
	)
	
	, lutu AS (
		SELECT * FROM stats_all_time_luck
	)
	
SELECT * FROM lutussss