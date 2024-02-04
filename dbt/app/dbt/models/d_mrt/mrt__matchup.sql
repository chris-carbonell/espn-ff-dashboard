WITH

    raw AS (
        SELECT
            *
        FROM {{ ref('int__matchup') }}
    )

    , final AS (
        SELECT
            *
        FROM raw
    )

SELECT * FROM final