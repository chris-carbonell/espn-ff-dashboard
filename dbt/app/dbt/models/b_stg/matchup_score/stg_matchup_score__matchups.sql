WITH

	hilaw AS (
		SELECT
			request_id
			, request_url
			, res
		FROM {{ source('raw', 'matchup_score') }}
		LIMIT {{ var("limit", "ALL") }}
	)
	
	-- schedule
	-- each scoring period contiains the entire season's schedule of matchups
	, schedules AS (
		SELECT 
			request_id
			, res #>> '{seasonId}' AS season_id
			, res #>> '{scoringPeriodId}' AS scoring_period_id

			, JSONB_ARRAY_ELEMENTS(JSONB_EXTRACT_PATH(res, 'schedule')) AS schedule_json
			
		FROM hilaw
	)
	
	-- matchups
    -- team_id for home/away teams
    -- determination of which team won
    -- regular season vs playoff game type
    , matchups AS (
		SELECT
			request_id
			
			, season_id
			, scoring_period_id
			
			, schedule_json #>> '{id}' AS schedule_id
			, schedule_json #>> '{matchupPeriodId}' AS matchup_period_id
			
			, schedule_json #>> '{winner}' AS matchup_winner
			, schedule_json #>> '{playoffTierType}' AS matchup_playoff_tier_type
			
			-- home
			, schedule_json #>> '{home, teamId}' AS matchup_home_team_id
			, schedule_json #>> '{home, totalPoints}' AS matchup_home_total_points
			
			-- away
			, schedule_json #>> '{away, teamId}' AS matchup_away_team_id
			, schedule_json #>> '{away, totalPoints}' AS matchup_away_total_points

		FROM schedules
	)
	
	, lutu AS (
		SELECT * FROM matchups
	)
	
SELECT * FROM lutu

--WHERE scoring_period_id = matchup_period_id