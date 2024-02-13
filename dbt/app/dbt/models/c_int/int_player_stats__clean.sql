-- # Overview
-- clean up

WITH

    hilaw AS (
        SELECT * FROM {{ ref('stg_roster__player_stats') }}
    )

    -- clean
    -- round points scored
    , clean AS (
        SELECT
            player_id
            , player_full_name
			, position_name
			, position_abbrev
			, is_starter
			, is_on_bench
			, is_on_ir
			, season_id
			, scoring_period_id
            -- a_seed.stats.id is an integer
            , CAST(stat AS INTEGER) AS stat

            , ROUND(points_projected::NUMERIC, 2) AS points_projected
            , ROUND(points_actual::NUMERIC, 2) AS points_actual

        FROM hilaw
    )

    , lutu AS (
        SELECT * FROM clean
    )

SELECT * FROM lutu