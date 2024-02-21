WITH

	player_stats AS (
		SELECT * FROM {{ ref('int_player_stats__clean') }}
	)

	-- team_owners
	-- bridge between team and owners (members):
	-- members.member_id = teams.team_owner_member_id
	-- stats.team_id = teams.team_id
	, team_owners AS (
		SELECT DISTINCT
			t.season_id
			, t.scoring_period_id
			, t.team_id
			, t.team_owner_member_id
		FROM {{ ref('int_teams__clean') }} t
	)

	-- fct_points
	, fct_points AS (
		SELECT
			-- surrogate keys
			{{ dbt_utils.generate_surrogate_key(['ps.game_id', 'ps.stat_id']) }} as stat_key
			, {{ dbt_utils.generate_surrogate_key(['ps.game_id']) }} as game_key
			, {{ dbt_utils.generate_surrogate_key(['ps.game_id', 'ps.player_id']) }} as player_key
			, {{ dbt_utils.generate_surrogate_key(['ps.season_id', 'ps.scoring_period_id', 'ps.team_id']) }} as team_key
			, {{ dbt_utils.generate_surrogate_key(['ps.season_id', 'ps.scoring_period_id', 'ps.team_id']) }} as matchup_key
			, {{ dbt_utils.generate_surrogate_key(['ps.season_id', 'ps.scoring_period_id', 't.team_owner_member_id']) }} as member_key

			-- facts
			, ps.points_projected
			, ps.points_actual
				
		FROM player_stats ps

		LEFT JOIN team_owners t
		ON ps.season_id = t.season_id
			AND ps.scoring_period_id = t.scoring_period_id
			AND ps.team_id = t.team_id
	)

	, lutu AS (
		SELECT * FROM fct_points
	)
	
SELECT * FROM lutu