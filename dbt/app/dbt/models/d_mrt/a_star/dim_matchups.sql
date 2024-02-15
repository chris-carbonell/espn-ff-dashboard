WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_matchups__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'schedule_id']) }} as matchup_key

			-- info
			, season_id
			, scoring_period_id
			, schedule_id

            -- categories
            , matchup_playoff_tier_type
            , is_regular_season
            , is_playoffs

            -- winner
            , matchup_winner_team_id

            -- home
			, matchup_home_team_id
			, matchup_home_total_points
			
			-- away
			, matchup_away_team_id
			, matchup_away_total_points

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu