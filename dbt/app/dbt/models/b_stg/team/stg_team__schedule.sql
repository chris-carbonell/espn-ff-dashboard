WITH

	hilaw AS (
		SELECT
			request_id
			, request_url
			, res
		FROM {{ source('raw', 'team') }}
		LIMIT {{ var("limit", "ALL") }}
	)
	
	, lutu AS (
		SELECT * FROM hilaw
	)
	
SELECT * FROM lutu