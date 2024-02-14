WITH

    hilaw AS (
        SELECT * FROM {{ ref('stg_settings__scoring_periods') }}
    )

    -- scoring_periods
    -- cast
    , scoring_periods AS (
		SELECT
			CAST(season_id AS INTEGER) AS season_id
			, CAST(first_scoring_period AS INTEGER) AS first_scoring_period
			, CAST(final_scoring_period AS INTEGER) AS final_scoring_period
		FROM hilaw
	)

    -- scoring_periods_series
    -- get each scoring period for each season
    , scoring_periods_series AS (
        SELECT
            season_id
            , GENERATE_SERIES(first_scoring_period, final_scoring_period, 1) AS scoring_period_id
        FROM scoring_periods
    )
	
    , lutu AS (
        SELECT * FROM scoring_periods_series
    )

SELECT * FROM lutu