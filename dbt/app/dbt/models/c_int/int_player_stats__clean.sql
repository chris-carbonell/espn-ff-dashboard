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
            roster_id
            , player_id
            , player_full_name
            , point_type
            -- a_seed.stats.id is an integer
            , CAST(stat AS INTEGER) AS stat
            , ROUND(points::NUMERIC, 2) AS points
        FROM hilaw
    )

    , lutu AS (
        SELECT * FROM clean
    )

SELECT * FROM lutu