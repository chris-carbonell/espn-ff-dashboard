-- # Overview
-- compare control totals to totals with a dim join

-- # Quickstart
-- just update the `dim` and `fct` CTEs
-- and `dim_id` in the `c_points_indiv` CTE

WITH

    -- dim
	-- alias dim-specific fields
	-- so the d_points CTE doesn't have to change
	dim AS (
    	SELECT
    		player_key AS dim_key
    		, player_id AS dim_id
    	FROM d_mrt.dim_players
    )

	-- fct
	-- alias dim key
	-- so the d_points CTE doesn't have to change
	, fct AS (
		SELECT
			player_key AS dim_key
			, *
		FROM d_mrt.fct_points fp
	)
	
	, c_points_indiv AS (
		SELECT
            season_id
            , scoring_period_id
            , player_id AS dim_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_int.int_player_stats__clean
        
        GROUP BY season_id
        	, scoring_period_id
        	, dim_id
	)

	, c_totals AS (
        SELECT
            season_id
            , scoring_period_id

            , SUM(points_actual) AS points_actual
            , SUM(points_projected) AS points_projected

        FROM c_points_indiv
        
        GROUP BY season_id
        	, scoring_period_id
    )

	, d_points_indiv AS (
		SELECT
			g.season_id
			, g.scoring_period_id
			
			, dim.dim_key
			, dim.dim_id
			
			, SUM(fp.points_actual) AS points_actual
			, SUM(fp.points_projected) AS points_projected
		
		FROM fct fp
		
		LEFT JOIN d_mrt.dim_games g
		ON fp.game_key = g.game_key
		
		LEFT JOIN dim
		ON fp.dim_key = dim.dim_key
		
		-- if the keys don't match (e.g., didn't update the input CTEs correctly)
		-- I want the totals to show a mismatch
		-- if we didn't have this WHERE clause, the totals would match exactly
		-- eventhough none of the keys matched
		WHERE dim.dim_key IS NOT NULL
		
		GROUP BY g.season_id
			, g.scoring_period_id
			, dim.dim_key
			, dim.dim_id
			
		ORDER BY g.season_id
			, g.scoring_period_id
			, dim.dim_key
			, dim.dim_id
	)

	, d_points AS (
		SELECT
			season_id
			, scoring_period_id
			
			, dim_id
			
			, SUM(points_actual) AS points_actual
			, SUM(points_projected) AS points_projected
		
		FROM d_points_indiv
		
		GROUP BY season_id
			, scoring_period_id
			, dim_id
			
		ORDER BY season_id
			, scoring_period_id
			, dim_id
	)
	
	, d_totals AS (
		SELECT
			season_id
			, scoring_period_id
			
			, SUM(points_actual) AS points_actual
			, SUM(points_projected) AS points_projected
			
		FROM d_points
		
		GROUP BY season_id
			, scoring_period_id
			
		ORDER BY season_id
			, scoring_period_id
	)
	
	, comparison AS (
		SELECT
			COALESCE(c.season_id, d.season_id) AS season_id
			, COALESCE(c.scoring_period_id, d.scoring_period_id) AS scoring_period_id
			
			-- control
			, c.points_actual AS c_points_actual
			, c.points_projected AS c_points_projected
			
			-- test
			, d.points_actual AS d_points_actual
			, d.points_projected AS d_points_projected
			
			-- difference
			, d.points_actual - c.points_actual AS diff_points_actual
			, d.points_projected - c.points_projected AS diff_points_projected
		
		FROM c_totals c
		
		FULL OUTER JOIN d_totals d
		ON c.season_id = d.season_id
			AND c.scoring_period_id = d.scoring_period_id
	)
	
	, missing_from_dim AS (
		SELECT
			COALESCE(c.season_id, d.season_id) AS season_id
			, COALESCE(c.scoring_period_id, d.scoring_period_id) AS scoring_period_id
			
			, d.dim_key
			, COALESCE(c.dim_id, d.dim_id) AS dim_id
			
			-- control
			, c.points_actual AS c_points_actual
			, c.points_projected AS c_points_projected
			
			-- test
			, d.points_actual AS d_points_actual
			, d.points_projected AS d_points_projected
			
			-- difference
			, d.points_actual - c.points_actual AS diff_points_actual
			, d.points_projected - c.points_projected AS diff_points_projected
		
		FROM c_points_indiv c
		
		FULL OUTER JOIN d_points_indiv d
		ON c.dim_id = d.dim_id
			AND c.season_id = d.season_id
			AND c.scoring_period_id = d.scoring_period_id
			
		WHERE c.season_id IS NULL
			OR c.scoring_period_id IS NULL
			OR c.dim_id IS NULL
	)
	
SELECT * FROM comparison
	
-- SELECT
-- 	*
-- FROM d_mrt.dim_players
-- WHERE player_key IN (SELECT dim_key FROM missing_from_dim)

-- # Comparison
-- | season_id | scoring_period_id | c_points_actual | c_points_projected | d_points_actual | d_points_projected | diff_points_actual | diff_points_projected |
-- |-----------|-------------------|-----------------|--------------------|-----------------|--------------------|--------------------|-----------------------|
-- | 2020      | 1                 | 2081.60         | 1978.01            | 2081.60         | 1978.01            | 0.00               | 0.00                  |
-- | 2020      | 2                 | 2142.36         | 1970.84            | 2142.36         | 1970.84            | 0.00               | 0.00                  |
-- | 2020      | 3                 | 1987.22         | 1915.31            | 1987.22         | 1915.31            | 0.00               | 0.00                  |
-- | 2020      | 4                 | 1911.54         | 1847.84            | 1911.54         | 1847.84            | 0.00               | 0.00                  |
-- | 2020      | 5                 | 1841.58         | 1834.75            | 1841.58         | 1834.75            | 0.00               | 0.00                  |
-- | 2020      | 6                 | 1748.54         | 1813.56            | 1748.54         | 1813.56            | 0.00               | 0.00                  |
-- | 2020      | 7                 | 1839.16         | 1851.53            | 1839.16         | 1851.53            | 0.00               | 0.00                  |
-- | 2020      | 8                 | 1689.90         | 1805.36            | 1689.90         | 1805.36            | 0.00               | 0.00                  |
-- | 2020      | 9                 | 1725.06         | 1782.70            | 1725.06         | 1782.70            | 0.00               | 0.00                  |
-- | 2020      | 10                | 1705.40         | 1807.02            | 1705.40         | 1807.02            | 0.00               | 0.00                  |
-- | 2020      | 11                | 1836.24         | 1881.32            | 1836.24         | 1881.32            | 0.00               | 0.00                  |
-- | 2020      | 12                | 1927.02         | 1958.33            | 1927.02         | 1958.33            | 0.00               | 0.00                  |
-- | 2020      | 13                | 1845.90         | 1911.91            | 1845.90         | 1911.91            | 0.00               | 0.00                  |
-- | 2020      | 14                | 1909.40         | 1958.54            | 1909.40         | 1958.54            | 0.00               | 0.00                  |
-- | 2020      | 15                | 2010.68         | 1984.85            | 2010.68         | 1984.85            | 0.00               | 0.00                  |
-- | 2020      | 16                | 2012.14         | 1968.65            | 2012.14         | 1968.65            | 0.00               | 0.00                  |
-- | 2021      | 1                 | 1993.72         | 1915.80            | 1993.72         | 1915.80            | 0.00               | 0.00                  |
-- | 2021      | 2                 | 1879.68         | 1952.21            | 1879.68         | 1952.21            | 0.00               | 0.00                  |
-- | 2021      | 3                 | 1923.88         | 2002.76            | 1923.88         | 2002.76            | 0.00               | 0.00                  |
-- | 2021      | 4                 | 1902.12         | 1953.13            | 1902.12         | 1953.13            | 0.00               | 0.00                  |
-- | 2021      | 5                 | 2061.40         | 2003.31            | 2061.40         | 2003.31            | 0.00               | 0.00                  |
-- | 2021      | 6                 | 1800.96         | 1826.45            | 1800.96         | 1826.45            | 0.00               | 0.00                  |
-- | 2021      | 7                 | 1605.96         | 1591.58            | 1605.96         | 1591.58            | 0.00               | 0.00                  |
-- | 2021      | 8                 | 1624.02         | 1813.98            | 1624.02         | 1813.98            | 0.00               | 0.00                  |
-- | 2021      | 9                 | 1578.04         | 1702.04            | 1578.04         | 1702.04            | 0.00               | 0.00                  |
-- | 2021      | 10                | 1562.60         | 1785.35            | 1562.60         | 1785.35            | 0.00               | 0.00                  |
-- | 2021      | 11                | 1663.56         | 1810.39            | 1663.56         | 1810.39            | 0.00               | 0.00                  |
-- | 2021      | 12                | 1708.12         | 1826.25            | 1708.12         | 1826.25            | 0.00               | 0.00                  |
-- | 2021      | 13                | 1659.76         | 1732.76            | 1659.76         | 1732.76            | 0.00               | 0.00                  |
-- | 2021      | 14                | 1712.08         | 1669.55            | 1712.08         | 1669.55            | 0.00               | 0.00                  |
-- | 2021      | 15                | 1643.82         | 1844.45            | 1643.82         | 1844.45            | 0.00               | 0.00                  |
-- | 2021      | 16                | 1721.18         | 1758.51            | 1721.18         | 1758.51            | 0.00               | 0.00                  |
-- | 2021      | 17                | 1870.66         | 1789.25            | 1870.66         | 1789.25            | 0.00               | 0.00                  |
-- | 2022      | 1                 | 1843.74         | 1951.91            | 1843.74         | 1951.91            | 0.00               | 0.00                  |
-- | 2022      | 2                 | 1832.30         | 1890.79            | 1832.30         | 1890.79            | 0.00               | 0.00                  |
-- | 2022      | 3                 | 1828.42         | 1934.15            | 1828.42         | 1934.15            | 0.00               | 0.00                  |
-- | 2022      | 4                 | 1840.86         | 1914.86            | 1840.86         | 1914.86            | 0.00               | 0.00                  |
-- | 2022      | 5                 | 1886.06         | 1922.99            | 1886.06         | 1922.99            | 0.00               | 0.00                  |
-- | 2022      | 6                 | 1499.68         | 1611.54            | 1499.68         | 1611.54            | 0.00               | 0.00                  |
-- | 2022      | 7                 | 1594.78         | 1620.63            | 1594.78         | 1620.63            | 0.00               | 0.00                  |
-- | 2022      | 8                 | 1858.62         | 1698.01            | 1858.62         | 1698.01            | 0.00               | 0.00                  |
-- | 2022      | 9                 | 1504.34         | 1516.24            | 1504.34         | 1516.24            | 0.00               | 0.00                  |
-- | 2022      | 10                | 1690.86         | 1656.75            | 1690.86         | 1656.75            | 0.00               | 0.00                  |
-- | 2022      | 11                | 1547.26         | 1577.86            | 1547.26         | 1577.86            | 0.00               | 0.00                  |
-- | 2022      | 12                | 1765.10         | 1811.13            | 1765.10         | 1811.13            | 0.00               | 0.00                  |
-- | 2022      | 13                | 1746.62         | 1769.90            | 1746.62         | 1769.90            | 0.00               | 0.00                  |
-- | 2022      | 14                | 1537.52         | 1539.40            | 1537.52         | 1539.40            | 0.00               | 0.00                  |
-- | 2022      | 15                | 1838.54         | 1769.75            | 1838.54         | 1769.75            | 0.00               | 0.00                  |
-- | 2022      | 16                | 1718.74         | 1741.07            | 1718.74         | 1741.07            | 0.00               | 0.00                  |
-- | 2022      | 17                | 1604.46         | 1738.61            | 1604.46         | 1738.61            | 0.00               | 0.00                  |
-- | 2023      | 1                 | 1687.10         | 1924.97            | 1687.10         | 1924.97            | 0.00               | 0.00                  |
-- | 2023      | 2                 | 1994.86         | 1932.05            | 1994.86         | 1932.05            | 0.00               | 0.00                  |
-- | 2023      | 3                 | 1920.28         | 1898.18            | 1920.28         | 1898.18            | 0.00               | 0.00                  |
-- | 2023      | 4                 | 1883.74         | 1951.18            | 1883.74         | 1951.18            | 0.00               | 0.00                  |
-- | 2023      | 5                 | 1779.54         | 1759.25            | 1779.54         | 1759.25            | 0.00               | 0.00                  |
-- | 2023      | 6                 | 1654.10         | 1856.44            | 1654.10         | 1856.44            | 0.00               | 0.00                  |
-- | 2023      | 7                 | 1666.52         | 1615.05            | 1666.52         | 1615.05            | 0.00               | 0.00                  |
-- | 2023      | 8                 | 2020.00         | 1959.47            | 2020.00         | 1959.47            | 0.00               | 0.00                  |
-- | 2023      | 9                 | 1581.48         | 1652.65            | 1581.48         | 1652.65            | 0.00               | 0.00                  |
-- | 2023      | 10                | 1774.76         | 1704.96            | 1774.76         | 1704.96            | 0.00               | 0.00                  |
-- | 2023      | 11                | 1695.60         | 1776.70            | 1695.60         | 1776.70            | 0.00               | 0.00                  |
-- | 2023      | 12                | 1982.90         | 1944.24            | 1982.90         | 1944.24            | 0.00               | 0.00                  |
-- | 2023      | 13                | 1649.26         | 1598.50            | 1649.26         | 1598.50            | 0.00               | 0.00                  |
-- | 2023      | 14                | 1761.48         | 1763.61            | 1761.48         | 1763.61            | 0.00               | 0.00                  |
-- | 2023      | 15                | 1815.14         | 1830.77            | 1815.14         | 1830.77            | 0.00               | 0.00                  |
-- | 2023      | 16                | 1848.20         | 1824.45            | 1848.20         | 1824.45            | 0.00               | 0.00                  |
-- | 2023      | 17                | 1777.84         | 1817.30            | 1777.84         | 1817.30            | 0.00               | 0.00                  |