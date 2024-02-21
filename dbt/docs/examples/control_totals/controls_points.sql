-- # Overview
-- * control totals for points

WITH

    points AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_int.int_player_stats__clean

        GROUP BY 1, 2
        ORDER BY 1, 2
    )

    , points_all AS (
        SELECT
            SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM points
    )

    , points_season AS (
        SELECT
            season_id
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM points
        GROUP BY 1
        ORDER BY 1
    )

    , points_scoring_period AS (
        SELECT
            scoring_period_id
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM points
        GROUP BY 1
        ORDER BY 1
    )

    , controls AS (
        SELECT
            'points_all' AS controls
            , NULL AS grouping
            , points_actual
            , points_projected
        FROM points_all

        UNION ALL

        SELECT
            'points_season' AS controls
            , season_id AS grouping
            , points_actual
            , points_projected
        FROM points_season
        
        UNION ALL
        
        SELECT
            'points_season' AS controls
            , NULL AS grouping
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM points_season
        
        UNION ALL

        SELECT
            'points_scoring_period' AS controls
            , scoring_period_id AS grouping
            , points_actual
            , points_projected
        FROM points_scoring_period
        
        UNION ALL
        
        SELECT
            'points_scoring_period' AS controls
            , NULL AS grouping
            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected
        FROM points_scoring_period
    )

SELECT * FROM controls

-- | points_all            |      | 119756.00 | 121723.65 |
-- |-----------------------|------|-----------|-----------|
-- | points_season         | 2020 | 30213.74  | 30270.52  |
-- | points_season         | 2021 | 29911.56  | 30977.77  |
-- | points_season         | 2022 | 29137.90  | 29665.59  |
-- | points_season         | 2023 | 30492.80  | 30809.77  |
-- | points_season         |      | 119756.00 | 121723.65 |
-- | points_scoring_period | 1    | 7606.16   | 7770.69   |
-- | points_scoring_period | 2    | 7849.20   | 7745.89   |
-- | points_scoring_period | 3    | 7659.80   | 7750.40   |
-- | points_scoring_period | 4    | 7538.26   | 7667.01   |
-- | points_scoring_period | 5    | 7568.58   | 7520.30   |
-- | points_scoring_period | 6    | 6703.28   | 7107.99   |
-- | points_scoring_period | 7    | 6706.42   | 6678.79   |
-- | points_scoring_period | 8    | 7192.54   | 7276.82   |
-- | points_scoring_period | 9    | 6388.92   | 6653.63   |
-- | points_scoring_period | 10   | 6733.62   | 6954.08   |
-- | points_scoring_period | 11   | 6742.66   | 7046.27   |
-- | points_scoring_period | 12   | 7383.14   | 7539.95   |
-- | points_scoring_period | 13   | 6901.54   | 7013.07   |
-- | points_scoring_period | 14   | 6920.48   | 6931.10   |
-- | points_scoring_period | 15   | 7308.18   | 7429.82   |
-- | points_scoring_period | 16   | 7300.26   | 7292.68   |
-- | points_scoring_period | 17   | 5252.96   | 5345.16   |
-- | points_scoring_period |      | 119756.00 | 121723.65 |