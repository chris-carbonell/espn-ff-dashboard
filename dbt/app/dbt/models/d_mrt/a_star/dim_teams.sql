WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_team_info__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['team_id']) }} as team_key

            -- team
            , team_logo
			, team_name
			, team_abbrev
			, team_owner
			
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