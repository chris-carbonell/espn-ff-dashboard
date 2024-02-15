WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_teams__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'team_id']) }} as team_key

			-- info
			, season_id
			, scoring_period_id
			, team_id

            -- team
            , team_logo
			, team_name
			, team_abbrev
			, team_owner_member_id
			
			-- record
			, team_record_ties
			, team_record_wins
			, team_record_losses
			
			-- points
			, team_points_for
			, team_points_against
			
			-- stats
			, team_values_by_stat
			
			-- transactions
			, team_transactions_misc
			, team_transactions_paid
			, team_transactions_drops
			, team_transactions_trades
			, team_transactions_move_to_ir
			, team_transactions_team_charges
			, team_transactions_acquisitions
			, team_transactions_move_to_active

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu