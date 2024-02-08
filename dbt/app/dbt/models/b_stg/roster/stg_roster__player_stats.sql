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
			, res
		FROM a_raw.roster
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
	
	-- players
	, players AS (
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
			, stats #>> '{id}' AS player_stats_id
            -- applied total not needed because, when the stats are broken out,
            -- they'll total out to the applied total
            -- this might be nice for verification in the future
			-- , stats #> '{appliedTotal}' AS applied_total
			, stats #> '{appliedStats}' AS applied_stats
			
		FROM players
	)
	
	-- rank_player_stats_all
    -- get rank based on length of player_stats_id
    , rank_player_stats_all AS (
		SELECT
			*
			, RANK() OVER(PARTITION BY roster_id, player_id ORDER BY LENGTH(player_stats_id) DESC) AS rank
		FROM player_stats_all
	)
	
	-- player_stats_real
    -- assume longest ID is the real ID
    , player_stats_real AS (
		SELECT
			roster_id
			, player_id
			, player_full_name
			, player_stats_id
			, applied_stats
		FROM rank_player_stats_all
		WHERE rank = 1
	)
	
	-- player_stats_each
    -- get each stat its own row
    , player_stats_each AS (
		SELECT
			p.roster_id
			, p.player_id
			, p.player_full_name
			, p.player_stats_id
			
			, stats.key AS stat
			, stats.value AS points_scored
			
		FROM player_stats_real p
		CROSS JOIN JSONB_EACH_TEXT(applied_stats) stats
	)
	
	, lutu AS (
		SELECT * FROM player_stats_each
	)
	
SELECT * FROM lutu