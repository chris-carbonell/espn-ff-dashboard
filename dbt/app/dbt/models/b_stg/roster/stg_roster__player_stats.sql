-- # Overview
-- extract player stats

-- # Notes
-- * the good data sits in `res['teams'][0]['roster']['entries'][0]['playerPoolEntry']['player']['stats']`
-- * the hackiest bit here is assuming that, in the stats object, the longest ID corresponds to the actual stats
--     * the other objects there look like projections
--     * I couldn't find those IDs anywhere else (I'm guessing they're unique to the league's settings)

WITH

	hilaw AS (
		SELECT
			roster_id
			, request_url
			, res
		FROM {{ source('raw', 'roster') }}
	)
	
	-- constants
	, constants AS (
		SELECT
			roster_id
			, CAST(res #>> '{seasonId}' AS INTEGER) AS season_id
			, CAST(res #>> '{scoringPeriodId}' AS INTEGER) AS scoring_period_id
		FROM hilaw
	)

	-- teams
    -- get teams objects into their own rows
    , teams AS (
		SELECT 
			roster_id
			, JSONB_ARRAY_ELEMENTS(JSONB_EXTRACT_PATH(res, 'teams')) AS teams
		FROM hilaw
	)
	
	-- check_teams
	-- 12 records for each roster_id
	-- one for each team
	-- , check_teams AS (
	-- 	SELECT 
	-- 		roster_id
	-- 		, COUNT(*) AS cnt_records
	-- 	FROM teams
	-- 	GROUP BY roster_id
	-- )
	
	-- entries
    -- get entries into their own rows
    , entries AS (
		SELECT
			roster_id
			, JSONB_ARRAY_ELEMENTS(teams #> '{roster, entries}') AS entries
		FROM teams
	)
	
	-- check_entries
	-- for each team (12), each roster spot (incl. bench and IR) (19)
	-- max = 12 x 19 = 228
	-- not all people use all roster spots so this is likely to be less than the max
	-- , check_entries AS (
	-- 	SELECT
	-- 		roster_id
	-- 		, COUNT(*) AS cnt_records
	-- 	FROM entries
	-- 	GROUP BY roster_id
	-- )
	
	-- player_stats
	-- extract stats objects for each player
	, player_stats AS (
		SELECT
			roster_id
			, entries #>> '{playerPoolEntry, player, fullName}' AS player_full_name
			, entries #>> '{playerPoolEntry, player, id}' AS player_id
			, JSONB_ARRAY_ELEMENTS(entries #> '{playerPoolEntry, player, stats}') AS stats
		FROM entries
	)
	
	-- player_stats_all
    -- incl. projections and real stats
    , player_stats_all AS (
		SELECT
			roster_id
			, player_id
			, player_full_name
			
			, CAST(stats #>> '{seasonId}' AS INTEGER) AS season_id
			, CAST(stats #>> '{scoringPeriodId}' AS INTEGER) AS scoring_period_id
			
			, stats #>> '{id}' AS player_stats_id
			
			-- actual points
			-- the real stats have statSourceId = 0 and statSplitTypeId = 1
			, stats #>> '{statSourceId}' AS stat_source_id
			, stats #>> '{statSplitTypeId}' AS stat_split_type_id
			
			-- project points
			, stats #>> '{externalId}' AS external_id
			
            -- applied total not needed because, when the stats are broken out,
            -- they'll total out to the applied total
            -- this might be nice for verification in the future
			-- , stats #> '{appliedTotal}' AS applied_total
			, stats #> '{appliedStats}' AS applied_stats
			
		FROM player_stats
	)
	
	-- player_stats_current
	-- just keep the stats from the current scoring period
	, player_stats_current AS (
		SELECT
			p.roster_id
			, p.player_id
			, p.player_full_name
			, p.season_id
			, p.scoring_period_id
			, p.player_stats_id
			, p.stat_source_id
			, p.stat_split_type_id
			, p.external_id
			, p.applied_stats
			
		FROM player_stats_all p
		
		INNER JOIN constants c
		ON p.roster_id = c.roster_id
		
		WHERE p.season_id = c.season_id
			AND p.scoring_period_id = c.scoring_period_id
	)

	-- player_stats_current_each
    -- get each stat its own row
    , player_stats_current_each AS (
		SELECT
			p.roster_id
			, p.player_id
			, p.player_full_name
			, p.season_id
			, p.scoring_period_id
			, p.player_stats_id
			, p.stat_source_id
			, p.stat_split_type_id
			, p.external_id
			
			, stats.key AS stat
			, ROUND(stats.value::NUMERIC, 2) AS points
			
		FROM player_stats_current p
		CROSS JOIN JSONB_EACH_TEXT(applied_stats) stats
	)
	
	-- player_stats_current_each_actual
    , player_stats_current_each_actual AS (
		SELECT
			roster_id
			, player_id
			, player_full_name
			, season_id
			, scoring_period_id
			, stat
			
			, points AS points_actual

		FROM player_stats_current_each
		WHERE scoring_period_id != '0'
			AND stat_source_id = '0'
			AND stat_split_type_id = '1'
	)
	
	-- player_stats_current_each_projected
    , player_stats_current_each_projected AS (
		SELECT
			roster_id
			, player_id
			, player_full_name
			, season_id
			, scoring_period_id
			, stat
			
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
			COALESCE(p.player_id, a.player_id) AS player_id
			, COALESCE(p.player_full_name, a.player_full_name) AS player_full_name
			, COALESCE(p.season_id, a.season_id) AS season_id
			, COALESCE(p.scoring_period_id, a.scoring_period_id) AS scoring_period_id
			, COALESCE(p.stat, a.stat) AS stat
			
			, COALESCE(p.points_projected, 0) AS points_projected
			, COALESCE(a.points_actual, 0) AS points_actual

		FROM player_stats_current_each_projected p

		FULL OUTER JOIN player_stats_current_each_actual a
		ON p.roster_id = a.roster_id
			AND p.player_id = a.player_id
		AND p.player_full_name = a.player_full_name 
		AND p.season_id = a.season_id
		AND p.scoring_period_id = a.scoring_period_id
		AND p.stat = a.stat
	)
	
	, lutu AS (
		SELECT * FROM player_stats_current_each_actual_and_projected
	)

SELECT * FROM lutu