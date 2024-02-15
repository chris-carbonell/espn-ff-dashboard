WITH

    hilaw AS (
        SELECT * FROM {{ ref('stg_matchup_score__matchups') }}
    )

    -- matchups
    , matchups AS (
		SELECT
			CAST(season_id AS INTEGER) AS season_id
			, CAST(scoring_period_id AS INTEGER) AS scoring_period_id

            , CAST(schedule_id AS INTEGER) AS schedule_id

            , matchup_winner

			, matchup_playoff_tier_type
            , CASE
                WHEN UPPER(matchup_playoff_tier_type) = 'NONE' THEN 1
                ELSE 0
            END AS is_regular_season
            , CASE
                WHEN UPPER(matchup_playoff_tier_type) = 'WINNERS_BRACKET' THEN 1
                ELSE 0
            END AS is_playoffs
			
			-- home
			, CAST(matchup_home_team_id AS INTEGER) AS matchup_home_team_id
			, ROUND(matchup_home_total_points::NUMERIC, 2) AS matchup_home_total_points
			
			-- away
            , CAST(matchup_away_team_id AS INTEGER) AS matchup_away_team_id
            , ROUND(matchup_away_total_points::NUMERIC, 2) AS matchup_away_total_points
		
        FROM hilaw

        -- each schedule contains all of the matchups
        -- so just keep the relevant matchups for each scoring period
        WHERE scoring_period_id = matchup_period_id
	)
    
    -- matchups_home
    -- get W/L determination from perspective of home team
    , matchups_home AS (
    	SELECT
    		-- info
			season_id
			, scoring_period_id
			, schedule_id
			, matchup_home_team_id AS team_id

            -- categories
            , matchup_playoff_tier_type
            , is_regular_season
            , is_playoffs
            
            -- opponent
            , matchup_away_team_id AS opponent_team_id
            
            -- win/loss
            , CASE
                WHEN UPPER(matchup_winner) = 'HOME' THEN 1
                WHEN UPPER(matchup_winner) = 'AWAY' THEN 0
                WHEN UPPER(matchup_winner) = 'UNDECIDED' THEN NULL  -- in the playoff bye weeks, the teams are designated as home
                ELSE NULL
            END AS team_won
            , CASE
                WHEN UPPER(matchup_winner) = 'HOME' THEN 0
                WHEN UPPER(matchup_winner) = 'AWAY' THEN 1
                WHEN UPPER(matchup_winner) = 'UNDECIDED' THEN NULL  -- in the playoff bye weeks, the teams are designated as home
                ELSE NULL
            END AS team_lost
            , CASE
                WHEN UPPER(matchup_winner) IN ('HOME', 'AWAY') THEN 0
                WHEN matchup_home_total_points = matchup_away_total_points THEN 1
                ELSE 0
            END AS team_tied
            
            -- points
            , matchup_home_total_points AS team_points
            , matchup_away_total_points AS opponent_points
            
    	FROM matchups
    )
    
    -- matchups_away
    -- get W/L determination from perspective of away team
    , matchups_away AS (
    	SELECT
    		-- info
			season_id
			, scoring_period_id
			, schedule_id
			, matchup_away_team_id AS team_id

            -- categories
            , matchup_playoff_tier_type
            , is_regular_season
            , is_playoffs
            
            -- opponent
            , matchup_home_team_id AS opponent_team_id
            
            -- win/loss
            , CASE
                WHEN UPPER(matchup_winner) = 'HOME' THEN 0
                WHEN UPPER(matchup_winner) = 'AWAY' THEN 1
                WHEN UPPER(matchup_winner) = 'UNDECIDED' THEN NULL  -- in the playoff bye weeks, the teams are designated as home
                ELSE NULL
            END AS team_won
            , CASE
                WHEN UPPER(matchup_winner) = 'HOME' THEN 1
                WHEN UPPER(matchup_winner) = 'AWAY' THEN 0
                WHEN UPPER(matchup_winner) = 'UNDECIDED' THEN NULL  -- in the playoff bye weeks, the teams are designated as home
                ELSE NULL
            END AS team_lost
            , CASE
                WHEN UPPER(matchup_winner) IN ('HOME', 'AWAY') THEN 0
                WHEN matchup_home_total_points = matchup_away_total_points THEN 1
                ELSE 0
            END AS team_tied
            
            -- points
            , matchup_away_total_points AS team_points
            , matchup_home_total_points AS opponent_points
            
    	FROM matchups
    )
    
    , matchups_stacked AS (
    	(
	    	SELECT * FROM matchups_home
	    	UNION ALL
	    	SELECT * FROM matchups_away
    	)
    	ORDER BY season_id, scoring_period_id, schedule_id, team_id
    )
	
    , lutu AS (
        SELECT * FROM matchups_stacked
    )

SELECT * FROM lutu