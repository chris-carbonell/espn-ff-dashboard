WITH

	-- controls

    c_points AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_int.int_player_stats__clean

        GROUP BY 1, 2
        ORDER BY 1, 2
    )

    , c_points_all AS (
        SELECT
            SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM c_points
    )

    , c_points_season AS (
        SELECT
            season_id
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM c_points
        GROUP BY 1
        ORDER BY 1
    )

    , c_points_scoring_period AS (
        SELECT
            scoring_period_id
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM c_points
        GROUP BY 1
        ORDER BY 1
    )

    , c_totals AS (
        SELECT
            'points_all' AS total
            , 'all' AS grouping
            , points_actual
            , points_projected
        FROM c_points_all

        UNION ALL

        SELECT
            'points_season' AS total
            , season_id::TEXT AS grouping
            , points_actual
            , points_projected
        FROM c_points_season
        
        UNION ALL
        
        SELECT
            'points_season' AS total
            , 'all' AS grouping
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM c_points_season
        
        UNION ALL

        SELECT
            'points_scoring_period' AS total
            , LPAD(scoring_period_id::TEXT, 2, '0') AS grouping
            , points_actual
            , points_projected
        FROM c_points_scoring_period
        
        UNION ALL
        
        SELECT
            'points_scoring_period' AS total
            , 'all' AS grouping
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM c_points_scoring_period
    )

    -- obt

    , o_points AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM d_mrt.obt

        GROUP BY 1, 2
        ORDER BY 1, 2
    )

    , o_points_all AS (
        SELECT
            SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM o_points
    )

    , o_points_season AS (
        SELECT
            season_id
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM o_points
        GROUP BY 1
        ORDER BY 1
    )

    , o_points_scoring_period AS (
        SELECT
            scoring_period_id
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM o_points
        GROUP BY 1
        ORDER BY 1
    )

    , o_totals AS (
        SELECT
            'points_all' AS total
            , 'all' AS grouping
            , points_actual
            , points_projected
        FROM o_points_all

        UNION ALL

        SELECT
            'points_season' AS total
            , season_id::TEXT AS grouping
            , points_actual
            , points_projected
        FROM o_points_season
        
        UNION ALL
        
        SELECT
            'points_season' AS total
            , 'all' AS grouping
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM o_points_season
        
        UNION ALL

        SELECT
            'points_scoring_period' AS total
            , LPAD(scoring_period_id ::TEXT, 2, '0') AS grouping
            , points_actual
            , points_projected
        FROM o_points_scoring_period
        
        UNION ALL
        
        SELECT
            'points_scoring_period' AS total
            , 'all' AS grouping
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM o_points_scoring_period
    )
    
    -- comparison
    , comparison AS (
    	SELECT
    		COALESCE(c.total, o.total) AS total
            , COALESCE(c.grouping, o.grouping) AS grouping

            -- controls
            , c.points_actual AS c_points_actual
            , c.points_projected AS c_points_projected

            -- obt
            , o.points_actual AS o_points_actual
            , o.points_projected AS o_points_projected
            
            -- diff
            , o.points_actual - c.points_actual AS diff_points_actual
            , o.points_projected - c.points_projected AS diff_points_projected

    	FROM c_totals c
    	FULL OUTER JOIN o_totals o
    	ON c.total = o.total
    		AND c.grouping = o.grouping
    )
    
SELECT * FROM comparison