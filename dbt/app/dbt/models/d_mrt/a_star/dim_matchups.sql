WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_matchups__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'team_id']) }} as matchup_key

			-- info
			, season_id
			, scoring_period_id
            , schedule_id
			, team_id
            , opponent_team_id

            -- categories
            , matchup_playoff_tier_type
            , is_regular_season
            , is_playoffs

            -- win/loss/tie
            , team_won
            , team_lost
            , team_tied

            -- points
            , team_points
            , opponent_points

            -- power rankings
            , power_rank_team_wins
            , power_rank_team_losses
            , power_rank_team_ties
            , power_rank_win_pct
            , power_rank

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu