WITH

	hilaw AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

    , seed AS (
        SELECT * FROM {{ ref('stats') }}
    )

    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['season_id', 'scoring_period_id', 'stat_id']) }} as stat_key

            , season_id
            , scoring_period_id

            , stat_id

        FROM hilaw
    )

    , stats_extracted AS (
		SELECT
            d.stat_key

            , d.season_id
            , d.scoring_period_id

            , d.stat_id
            
            , s."displayAbbrev" AS stat_abbrev
            , s."statCategoryId" AS stat_category_id
            , s."statTypeId" AS stat_type_id
        
        FROM dim d

        LEFT JOIN seed s
        ON d.stat_id = s.id
	)

    , lutu AS (
        SELECT * FROM stats_extracted
    )
	
SELECT * FROM lutu