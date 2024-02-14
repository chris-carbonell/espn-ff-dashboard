WITH

	hilaw AS (
		SELECT * FROM {{ source('raw', 'settings') }}
	)
	
	-- scoring_periods_extracted
	-- first and final scoring periods by season
	, scoring_periods_extracted AS (
		SELECT DISTINCT
			res #>> '{seasonId}' AS season_id
			, res #>> '{status, firstScoringPeriod}' AS first_scoring_period
			, res #>> '{status, finalScoringPeriod}' AS final_scoring_period
		
		FROM hilaw
	)
	
	, lutu AS (
        SELECT * FROM scoring_periods_extracted
    )

SELECT * FROM lutu