-- # Overview
-- in dev, I like to limit the number of records so I can test faster
-- normally, I'd just have this as the first CTE in the staging script
-- however, I also need this for the `constants` CTE in the intermediate layer
-- and I wanted to be certain that the same record came back from LIMIT

WITH

	hilaw AS (
		SELECT
			roster_id
			, request_url
			, res
		FROM {{ source('raw', 'roster') }}
		LIMIT {{ var("limit", "ALL") }}
	)

    , lutu AS (
		SELECT * FROM hilaw
	)

SELECT * FROM lutu