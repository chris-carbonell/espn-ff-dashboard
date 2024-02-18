WITH

	hilaw AS (
		SELECT 
            * 
        FROM {{ source('raw', 'pro_team_schedules') }}
		LIMIT {{ var("limit", "ALL") }}
	)
	
	, pro_teams AS (
		SELECT
			request_id
			, request_url
			
			, SUBSTRING(request_url, '.*/seasons/(\d{4})') AS season_id
			
			, JSONB_ARRAY_ELEMENTS(res #> '{settings, proTeams}') AS pro_teams
			
		FROM hilaw
	)
	
	, schedules AS (
		SELECT
			pt.*
			
			, pro_teams #>> '{name}' AS pro_team_name
			, pro_teams #>> '{abbrev}' AS pro_team_abbrev
			, pro_teams #> '{byeWeek}' AS pro_team_bye_week
			, pro_teams #> '{id}' AS pro_team_id
			, pro_teams #>> '{location}' AS pro_team_location
			
			, JSONB_ARRAY_ELEMENTS(schedules.value) AS game
			
		FROM pro_teams pt
		
		CROSS JOIN JSONB_EACH(pro_teams #> '{proGamesByScoringPeriod}') AS schedules
	)
	
	-- controls_schedules_game_count 
	-- check to make sure each team in each season has the appropriate number of games
	, controls_schedules_game_count AS (
		SELECT 
			season_id
			, pro_team_abbrev
			, COUNT(*) AS cnt_records
		FROM schedules
		GROUP BY 1, 2
		ORDER BY 1, 2
	)
	
	, games AS (
		SELECT
			-- request
			s.request_id
			
			-- season
			, s.season_id
			
			-- team
			, s.pro_team_id
			, s.pro_team_name
			, s.pro_team_abbrev
			, s.pro_team_location
			, s.pro_team_bye_week 
			
			-- games
			, game #> '{scoringPeriodId}' AS scoring_period_id
			, game #> '{id}' AS game_id
			, game #> '{date}' AS dt_game
			, game #> '{homeProTeamId}' AS pro_team_id_home
			, game #> '{awayProTeamId}' AS pro_team_id_away
		
		FROM schedules s
	)
	
	-- controls_games_game_count 
	-- check to make sure each team in each season has the appropriate number of games
	, controls_games_game_count AS (
		SELECT 
			season_id
			, pro_team_abbrev
			, COUNT(*) AS cnt_records
		FROM games
		GROUP BY 1, 2
		ORDER BY 1, 2
	)
	
	, lutu AS (
		SELECT * FROM games
	)
	
SELECT * FROM lutu