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
			, CAST(matchup_home_total_points AS INTEGER) AS matchup_home_total_points
			
			-- away
            , CAST(matchup_away_team_id AS INTEGER) AS matchup_away_team_id
            , CAST(matchup_away_total_points AS INTEGER) AS matchup_away_total_points
		
        FROM hilaw

        -- each schedule contains all of the matchups
        -- so just keep the relevant matchups for each scoring period
        WHERE scoring_period_id = matchup_period_id
	)

    -- matchup_winners
    -- determine winners
    , matchup_winners AS (
        SELECT
            -- info
			, season_id
			, scoring_period_id
			, schedule_id

            -- categories
            , matchup_playoff_tier_type
            , is_regular_season
            , is_playoffs

            -- winner
            , CASE
                WHEN UPPER(matchup_winner) = 'HOME' THEN matchup_home_team_id
                WHEN UPPER(matchup_winner) = 'AWAY' THEN matchup_away_team_id
                WHEN UPPER(matchup_winner) = 'UNDECIDED' THEN NULL  -- in the playoff bye weeks, the teams are designated as home
                ELSE NULL
            END AS matchup_winner_team_id

            -- home
			, matchup_home_team_id
			, matchup_home_total_points
			
			-- away
			, matchup_away_team_id
			, matchup_away_total_points
            
        FROM matchups
    )
	
    , lutu AS (
        SELECT * FROM matchup_winners
    )

SELECT * FROM lutu