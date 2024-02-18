WITH

	hilaw AS (
		SELECT * FROM {{ ref('stg_pro_team_schedules__games') }}
	)
	
	, games AS (
		SELECT
			request_id
			
			, CAST(season_id AS INTEGER) AS season_id
			
			, CAST(pro_team_id AS INTEGER) AS pro_team_id
			, pro_team_name
			, pro_team_abbrev
			, pro_team_location
			, pro_team_bye_week
			
			, CAST(scoring_period_id AS INTEGER) AS scoring_period_id
			, game_id
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
			, TO_CHAR(ts_game, 'Day') AS game_dow
			
		FROM games
	)
	
	, lutu AS (
		SELECT * FROM game_dows
	)
	
SELECT * FROM lutu