WITH

	hilaw AS (
		SELECT
			team_id AS request_id
			, request_url
			, res
		FROM {{ source('raw', 'team') }}
		LIMIT {{ var("limit", "ALL") }}
	)
	
	-- teams_json
	-- get json of details of each team
	, teams_json AS (
		SELECT
			request_id
			, request_url

			, res #>> '{seasonId}' AS season_id
			, res #>> '{scoringPeriodId}' AS scoring_period_id

			, JSONB_ARRAY_ELEMENTS(JSONB_EXTRACT_PATH(res, 'teams')) AS team_json
			
		FROM hilaw
	)
	
    -- teams
    -- extract all the juicy data from that JSON object
    -- brought in a bunch of stuff to help with validation
	, teams AS (
		SELECT
			request_id
			, request_url

			, season_id
			, scoring_period_id
			
			, team_json #>> '{id}' AS team_id
			, team_json #>> '{logo}' AS team_logo
			, team_json #>> '{name}' AS team_name
			, team_json #>> '{name}' AS team_abbrev
			-- multiple members could own the team but, for the league I care about, only one member owns each team
			-- , team_json #> '{owners}' ->> 0 AS team_owner_member_id
			, team_json #>> '{primaryOwner}' AS team_owner_member_id
			
			-- record
			, team_json #>> '{record, overall, ties}' AS team_record_ties
			, team_json #>> '{record, overall, wins}' AS team_record_wins
			, team_json #>> '{record, overall, losses}' AS team_record_losses
			
			-- points
			, team_json #>> '{record, overall, pointsFor}' AS team_points_for
			, team_json #>> '{record, overall, pointsAgainst}' AS team_points_against
			
			-- stats
			, team_json #>> '{valuesByStat}' AS team_values_by_stat
			
			-- transactions
			, team_json #>> '{transactionCounter, misc}' AS team_transactions_misc
			, team_json #>> '{transactionCounter, paid}' AS team_transactions_paid
			, team_json #>> '{transactionCounter, drops}' AS team_transactions_drops
			, team_json #>> '{transactionCounter, trades}' AS team_transactions_trades
			, team_json #>> '{transactionCounter, moveToIR}' AS team_transactions_move_to_ir
			, team_json #>> '{transactionCounter, teamCharges}' AS team_transactions_team_charges
			, team_json #>> '{transactionCounter, acquisitions}' AS team_transactions_acquisitions
			, team_json #>> '{transactionCounter, moveToActive}' AS team_transactions_move_to_active
			
			, team_json
		
		FROM teams_json
	)
	
	, lutu AS (
		SELECT * FROM teams
	)
	
SELECT * FROM lutu