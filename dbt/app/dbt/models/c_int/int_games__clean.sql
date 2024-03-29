WITH

	hilaw AS (
		SELECT * FROM {{ ref('stg_pro_team_schedules__games') }}
	)
	
	-- games
	-- the scrape duplicates records
	-- because the schedule is scraped for the home team and the away team
	-- so use DISTINCT to deduplicate them
	, games AS (
		SELECT DISTINCT
			CAST(game_id AS BIGINT) AS game_id

			, CAST(season_id AS INTEGER) AS season_id
			, CAST(scoring_period_id AS INTEGER) AS scoring_period_id
			
			, TIMEZONE('America/Chicago', TO_TIMESTAMP(LEFT(epoch_game, -3):: BIGINT)) AS ts_game

			, CAST(pro_team_id_home AS INTEGER) AS pro_team_id_home
			, CAST(pro_team_id_away AS INTEGER) AS pro_team_id_away
			
		FROM hilaw
	)
	
	-- game_dows
    -- get day of week (e.g., "Sunday") from timestamp of game
    , game_dows AS (
		SELECT
			*
			
			-- dow = day of week
			, TO_CHAR(ts_game, 'Day') AS game_dow
			
			-- extract hour in prep for tod
			, EXTRACT(HOUR FROM ts_game) AS game_hour
			
		FROM games
	)
	
	, game_tods AS (
		SELECT
			*
			
			-- tod = time of day
			, CASE
				WHEN game_hour < 12 THEN 'morning'
				WHEN game_hour >= 12 AND game_hour < 15 THEN 'early_afternoon'
				WHEN game_hour >= 15 AND game_hour < 18 THEN 'late_afternoon'
				WHEN game_hour >= 18 THEN 'evening'
			END AS game_tod
			
		FROM game_dows
	)
	
	, lutu AS (
		SELECT * FROM game_tods
	)
	
SELECT * FROM lutu