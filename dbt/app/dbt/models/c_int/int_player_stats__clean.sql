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

	-- player_stats_current_each
    -- get each stat its own row
    , player_stats_current_each AS (
		SELECT
			p.request_id
			, p.team_id
			, p.player_id
			, p.player_full_name
			, p.position_name
			, p.position_abbrev
			, p.is_starter
			, p.is_on_bench
			, p.is_on_ir
			, p.season_id
			, p.scoring_period_id
			, p.player_stats_id
			, p.stat_source_id
			, p.stat_split_type_id
			, p.external_id
			
			, CAST(stats.key AS INTEGER) AS stat_id

			, ROUND(stats.value::NUMERIC, 2) AS points
			
		FROM player_stats_current p
		CROSS JOIN JSONB_EACH_TEXT(applied_stats) stats
	)
	
	-- player_stats_current_each_actual
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
			, stat_id
			
			, points AS points_actual

		FROM player_stats_current_each
		WHERE scoring_period_id != '0'
			AND stat_source_id = '0'
			AND stat_split_type_id = '1'
	)
	
	-- player_stats_current_each_projected
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
			, stat_id
			
			, points AS points_projected

		FROM player_stats_current_each
		WHERE scoring_period_id != '0'
			AND stat_source_id = '1'
			AND stat_split_type_id = '1'
			AND CAST(season_id AS VARCHAR) || CAST(scoring_period_id AS VARCHAR) = external_id
	)
	
	-- player_stats_current_each_actual_and_projected
	-- get project and actual points into their own columns
	, player_stats_current_each_actual_and_projected AS (
		SELECT
			COALESCE(p.team_id, a.team_id) AS team_id
			, COALESCE(p.player_id, a.player_id) AS player_id
			, COALESCE(p.player_full_name, a.player_full_name) AS player_full_name
			, COALESCE(p.position_name, a.position_name) AS position_name
			, COALESCE(p.position_abbrev, a.position_abbrev) AS position_abbrev
			, COALESCE(p.is_starter, a.is_starter) AS is_starter
			, COALESCE(p.is_on_bench, a.is_on_bench) AS is_on_bench
			, COALESCE(p.is_on_ir, a.is_on_ir) AS is_on_ir
			, COALESCE(p.season_id, a.season_id) AS season_id
			, COALESCE(p.scoring_period_id, a.scoring_period_id) AS scoring_period_id
			, COALESCE(p.stat_id, a.stat_id) AS stat_id
			
			, COALESCE(p.points_projected, 0) AS points_projected
			, COALESCE(a.points_actual, 0) AS points_actual

		FROM player_stats_current_each_projected p

		FULL OUTER JOIN player_stats_current_each_actual a
		ON p.request_id = a.request_id
			AND p.team_id = a.team_id
			AND p.player_id = a.player_id
			AND p.player_full_name = a.player_full_name 
			AND p.season_id = a.season_id
			AND p.scoring_period_id = a.scoring_period_id
			AND p.stat_id = a.stat_id
	)

    -- clean
    -- round points scored
    , clean AS (
        SELECT
            season_id
			, scoring_period_id

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

        FROM player_stats_current_each_actual_and_projected
    )

    , lutu AS (
        SELECT * FROM clean
    )

SELECT * FROM lutu