WITH

	hilaw AS (
		SELECT * FROM {{ ref('stg_team__teams') }}
	)
	
    -- teams
	, teams AS (
		SELECT
			CAST(season_id AS INTEGER) AS season_id
			, CAST(scoring_period_id AS INTEGER) AS scoring_period_id
			, CAST(team_id AS INTEGER) AS team_id

			-- team info
			, team_logo
			, team_name
			, team_abbrev
			, team_owner_member_id
			
			-- record
			, team_record_ties
			, team_record_wins
			, team_record_losses
			
			-- points
			, ROUND(team_points_for::NUMERIC, 2) AS team_points_for
			, ROUND(team_points_against::NUMERIC, 2) AS team_points_against
			
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
		SELECT * FROM teams
	)
	
SELECT * FROM lutu