WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

    , seed AS (
        SELECT * FROM {{ ref('stats') }}
    )

    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['stat']) }} as stat_key
            , stat
        FROM hilaw
    )

    , lutu AS (
		SELECT
            d.*
            , s."displayAbbrev" AS stat_abbrev
            , s."statCategoryId" AS stat_category_id
            , s."statTypeId" AS stat_type_id
        
        FROM dim d

        LEFT JOIN seed s
        ON d.stat = s.id
	)
	
SELECT * FROM lutu