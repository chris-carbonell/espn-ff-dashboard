-- # Overview
-- clean up

WITH

    hilaw AS (
        SELECT * FROM {{ ref('stg_roster__player_stats') }}
    )

	-- constants
	-- we need the season and scoring period
	-- to help identify the current scoring period's stats
	, constants AS (
		SELECT
			request_id
			, CAST(res #>> '{seasonId}' AS INTEGER) AS season_id
			, CAST(res #>> '{scoringPeriodId}' AS INTEGER) AS scoring_period_id
		FROM {{ ref("stg_roster__player_stats_raw") }}
	)

    -- player_stats_current
	-- just keep the stats from the current scoring period
	, player_stats_current AS (
		SELECT
			h.request_id
			, CAST(h.team_id AS INTEGER) AS team_id
			, h.player_id
			, h.player_full_name
			, h.position_name
			, h.position_abbrev

			, CASE
				WHEN h.position_abbrev IN ('IR', 'BE') THEN 0
				ELSE 1
			END AS is_starter
			, h.is_on_bench
			, CASE
				WHEN h.position_abbrev = 'IR' THEN TRUE
				ELSE FALSE
			END AS is_on_ir

			, CAST(h.season_id AS INTEGER) AS season_id
			, CAST(h.scoring_period_id AS INTEGER) AS scoring_period_id
			, h.player_stats_id
			, h.stat_source_id
			, h.stat_split_type_id
			, h.external_id
			, h.applied_stats
			
		FROM hilaw h
		
		INNER JOIN constants c
		ON h.request_id = c.request_id
		
		WHERE CAST(h.season_id AS INTEGER) = c.season_id
			AND CAST(h.scoring_period_id AS INTEGER) = c.scoring_period_id
	)

	-- player_stats_current_actual
    , player_stats_current_actual AS (
		SELECT
			request_id
			, team_id
			, external_id AS game_id
			, player_id
			, player_full_name
			, position_name
			, position_abbrev
			, is_starter
			, is_on_bench
			, is_on_ir
			, season_id
			, scoring_period_id
			, applied_stats AS applied_stats_actual

		FROM player_stats_current
		WHERE stat_source_id = '0'
			AND stat_split_type_id = '1'
	)
	
	-- player_stats_current_projected
    , player_stats_current_projected AS (
		SELECT
			request_id
			, team_id
			
			-- the external ID for projected points is NOT the game ID
			-- therefore, we set this to NULL and have COALESCE combine it with the
			-- actual game ID from the actual stats CTE above
			, NULL AS game_id
			
			, player_id
			, player_full_name
			, position_name
			, position_abbrev
			, is_starter
			, is_on_bench
			, is_on_ir
			, season_id
			, scoring_period_id
			, applied_stats AS applied_stats_projected

		FROM player_stats_current

		WHERE stat_source_id = '1'
			AND stat_split_type_id = '1'
			AND CAST(season_id AS VARCHAR) || CAST(scoring_period_id AS VARCHAR) = external_id
	)
	
	, player_stats_current_combined AS (
		SELECT
			COALESCE(a.request_id, p.request_id) AS request_id
			, COALESCE(a.team_id, p.team_id) AS team_id
			, COALESCE(a.game_id, p.game_id) AS game_id
			, COALESCE(a.player_id, p.player_id) AS player_id
			, COALESCE(a.player_full_name, p.player_full_name) AS player_full_name
			, COALESCE(a.position_name, p.position_name) AS position_name
			, COALESCE(a.position_abbrev, p.position_abbrev) AS position_abbrev
			, COALESCE(a.is_starter, p.is_starter) AS is_starter
			, COALESCE(a.is_on_bench, p.is_on_bench) AS is_on_bench
			, COALESCE(a.is_on_ir, p.is_on_ir) AS is_on_ir
			, COALESCE(a.season_id, p.season_id) AS season_id
			, COALESCE(a.scoring_period_id, p.scoring_period_id) AS scoring_period_id
			
			, a.applied_stats_actual
			, p.applied_stats_projected
		
		FROM player_stats_current_actual a
		
		FULL OUTER JOIN player_stats_current_projected p
		ON a.season_id = p.season_id
			AND a.scoring_period_id = p.scoring_period_id
			AND a.player_id = p.player_id
	)
	
	-- player_stats_current_combined_w_game
	-- get game ID from schedule if necessary
	, player_stats_current_combined_w_game AS (
		SELECT
			ps.request_id
			, ps.team_id
			, ps.player_id
			, ps.player_full_name
			, ps.position_name
			, ps.position_abbrev
			, ps.is_starter
			, ps.is_on_bench
			, ps.is_on_ir
			, ps.season_id
			, ps.scoring_period_id
			
			-- get game ID from schedules
			, COALESCE(ps.game_id, g.game_id) AS game_id

			, ps.applied_stats_actual
			, ps.applied_stats_projected
		
		FROM player_stats_current_combined ps
		
					
		LEFT JOIN b_stg.stg_pro_team_schedules__games g
		ON ps.season_id = g.season_id::INTEGER
			AND ps.scoring_period_id = g.scoring_period_id::INTEGER 
			AND ps.team_id = g.pro_team_id::INTEGER
	)
	
 	  -- player_stats_current_each_actual
	  -- get each stat its own row
    , player_stats_current_each_actual AS (
		SELECT
			request_id
			, team_id
			, player_id
			, player_full_name
			, position_name
			, position_abbrev
			, is_starter
			, is_on_bench
			, is_on_ir
			, season_id
			, scoring_period_id
			, game_id
			
			-- actual
			, CAST(stats_actual.key AS INTEGER) AS stat_id
			, ROUND(stats_actual.value::NUMERIC, 2) AS points
			
		FROM player_stats_current_combined_w_game
		CROSS JOIN JSONB_EACH_TEXT(applied_stats_actual) stats_actual
	)

	-- player_stats_current_each_projected
	  -- get each stat its own row
    , player_stats_current_each_projected AS (
		SELECT
			request_id
			, team_id
			, player_id
			, player_full_name
			, position_name
			, position_abbrev
			, is_starter
			, is_on_bench
			, is_on_ir
			, season_id
			, scoring_period_id
			, game_id
			
			-- projected
			, CAST(stats_projected.key AS INTEGER) AS stat_id
			, ROUND(stats_projected.value::NUMERIC, 2) AS points
			
		FROM player_stats_current_combined_w_game
		CROSS JOIN JSONB_EACH_TEXT(applied_stats_projected) stats_projected
	)
	
	, player_stats_current_each_combined AS (
		SELECT
			COALESCE(a.request_id, p.request_id) AS request_id
			, COALESCE(a.team_id, p.team_id) AS team_id
			, COALESCE(a.game_id, p.game_id) AS game_id
			, COALESCE(a.player_id, p.player_id) AS player_id
			, COALESCE(a.player_full_name, p.player_full_name) AS player_full_name
			, COALESCE(a.position_name, p.position_name) AS position_name
			, COALESCE(a.position_abbrev, p.position_abbrev) AS position_abbrev
			, COALESCE(a.is_starter, p.is_starter) AS is_starter
			, COALESCE(a.is_on_bench, p.is_on_bench) AS is_on_bench
			, COALESCE(a.is_on_ir, p.is_on_ir) AS is_on_ir
			, COALESCE(a.season_id, p.season_id) AS season_id
			, COALESCE(a.scoring_period_id, p.scoring_period_id) AS scoring_period_id
			, COALESCE(a.stat_id, p.stat_id) AS stat_id
			
			, a.points AS points_actual
			, p.points AS points_projected
		
		FROM player_stats_current_each_actual a
		
		FULL OUTER JOIN player_stats_current_each_projected p
		ON a.season_id = p.season_id
			AND a.scoring_period_id = p.scoring_period_id
			AND a.player_id = p.player_id
			AND a.stat_id = p.stat_id
	)

    -- clean
    -- round points scored
    , clean AS (
        SELECT
            season_id
			, scoring_period_id
			, game_id

			, team_id

			, player_id
            , player_full_name
			, position_name
			, position_abbrev

			, is_starter
			, is_on_bench
			, is_on_ir
			
            -- a_seed.stats.id is an integer
            , stat_id

            , ROUND(points_projected::NUMERIC, 2) AS points_projected
            , ROUND(points_actual::NUMERIC, 2) AS points_actual

			-- keys
			-- for tracing back
			, {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'stat_id']) }} as stat_key
			, {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id']) }} as time_key
			, {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'player_id']) }} as player_key
			, {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'team_id']) }} as team_key
			, {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'team_id']) }} as matchup_key

        FROM player_stats_current_each_combined
    )

    , lutu AS (
        SELECT * FROM clean
    )

SELECT * FROM lutu