WITH

	hilaw AS (
		SELECT * FROM {{ ref('stg_team__members') }}
	)

    -- dim
    , dim AS (
        SELECT DISTINCT
            {{ dbt_utils.generate_surrogate_key(['game_id', 'member_id']) }} as member_key

			-- info
			, season_id
			, scoring_period_id
			, member_id

            -- member
            , member_display_name
            , member_first_name
            , member_last_name

        FROM hilaw
    )

    , lutu AS (
		SELECT * FROM dim
	)
	
SELECT * FROM lutu