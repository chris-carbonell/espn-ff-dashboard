WITH

    raw AS (
        SELECT
            *
        FROM {{ source('raw', 'matchup') }}
    )

    , final AS (
        SELECT
            *
        FROM raw
    )

SELECT * FROM final