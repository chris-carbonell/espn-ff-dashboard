WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_scoring_periods__clean') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id']) }} as time_key
            
            , season_id
			, scoring_period_id

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu