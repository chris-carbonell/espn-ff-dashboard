WITH

    raw AS (
        SELECT
            *
        FROM {{ ref('stg__matchup') }}
    )

    , final AS (
        SELECT
            *
        FROM raw
    )

SELECT * FROM final