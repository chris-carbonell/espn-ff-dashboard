WITH

	hilaw AS (
		SELECT
			request_id
			, request_url
			, res
		FROM {{ source('raw', 'team') }}
		LIMIT {{ var("limit", "ALL") }}
	)
	
	-- members_json
	-- get json of details of each member
	, members_json AS (
		SELECT
			request_id
			, request_url

			, res #>> '{seasonId}' AS season_id
			, res #>> '{scoringPeriodId}' AS scoring_period_id

			, JSONB_ARRAY_ELEMENTS(JSONB_EXTRACT_PATH(res, 'members')) AS member_json
			
		FROM hilaw
	)
	
    -- members
    -- extract all the juicy data from that JSON object
	, members AS (
		SELECT
			request_id
			, request_url

			, season_id
			, scoring_period_id
			
			, member_json #>> '{id}' AS member_id
			, member_json #>> '{displayName}' AS member_display_name
			, member_json #>> '{firstName}' AS member_first_name
			, member_json #>> '{lastName}' AS member_last_name
			
			, member_json
		
		FROM members_json
	)
	
	, lutu AS (
		SELECT * FROM members
	)
	
SELECT * FROM lutu