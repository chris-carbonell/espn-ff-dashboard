-- # Overview
-- extract player stats

-- # Notes
-- * the good data sits in `res['teams'][0]['roster']['entries'][0]['playerPoolEntry']['player']['stats']`
-- * the hackiest bit here is assuming that, in the stats object, the longest ID corresponds to the actual stats
--     * the other objects there look like projections
--     * I couldn't find those IDs anywhere else (I'm guessing they're unique to the league's settings)

WITH

	hilaw AS (
		SELECT * FROM {{ ref("stg_roster__player_stats_raw") }}
	)
	
	, slots AS (
		SELECT * FROM {{ ref('slots') }}
	)

	-- teams
    -- get teams objects into their own rows
    , teams AS (
		SELECT 
			request_id
			, JSONB_ARRAY_ELEMENTS(JSONB_EXTRACT_PATH(res, 'teams')) AS teams
		FROM hilaw
	)
	
	-- check_teams
	-- 12 records for each request_id
	-- one for each team
	-- , check_teams AS (
	-- 	SELECT 
	-- 		request_id
	-- 		, COUNT(*) AS cnt_records
	-- 	FROM teams
	-- 	GROUP BY request_id
	-- )
	
	-- entries
    -- get entries into their own rows
    , entries AS (
		SELECT
			request_id
			, teams #>> '{id}' AS team_id
			, JSONB_ARRAY_ELEMENTS(teams #> '{roster, entries}') AS entries
		FROM teams
	)
	
	-- check_entries
	-- for each team (12), each roster spot (incl. bench and IR) (19)
	-- max = 12 x 19 = 228
	-- not all people use all roster spots so this is likely to be less than the max
	-- , check_entries AS (
	-- 	SELECT
	-- 		request_id
	-- 		, COUNT(*) AS cnt_records
	-- 	FROM entries
	-- 	GROUP BY request_id
	-- )
	
	-- player_stats
	-- extract stats objects for each player
	, player_stats AS (
		SELECT
			request_id
			, team_id
			, entries #>> '{playerPoolEntry, player, fullName}' AS player_full_name
			, entries #>> '{playerPoolEntry, player, id}' AS player_id
			
			, s.name AS position_name
			, s.abbrev AS position_abbrev
			, s.bench AS is_on_bench
			
			, JSONB_ARRAY_ELEMENTS(entries #> '{playerPoolEntry, player, stats}') AS stats
		
		FROM entries e
		
		LEFT JOIN slots s
		ON (entries #>> '{lineupSlotId}')::INTEGER = s.id
	)
	
	-- player_stats_all
    -- incl. projections and real stats
    , player_stats_all AS (
		SELECT
			request_id
			, team_id
			, player_id
			, player_full_name
			
			, position_name
			, position_abbrev
			, is_on_bench
			
			, stats #>> '{seasonId}' AS season_id
			, stats #>> '{scoringPeriodId}' AS scoring_period_id
			
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
	
	, lutu AS (
		SELECT * FROM player_stats_all
	)

SELECT * FROM lutu