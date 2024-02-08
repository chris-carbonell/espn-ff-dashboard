-- # Overview
-- clean up

WITH

    hilaw AS (
        SELECT
            *
        FROM {{ ref('stg_roster__player_stats') }}
    )

    -- clean
    -- round points scored
    , clean AS (
        SELECT
            roster_id
            , player_id
            , player_full_name
            , player_stats_id
            , stat
            , ROUND(points_scored::NUMERIC, 2) AS points_scored
        FROM hilaw
    )

    , lutu AS (
        SELECT
            *
        FROM clean
    )

SELECT * FROM lutu