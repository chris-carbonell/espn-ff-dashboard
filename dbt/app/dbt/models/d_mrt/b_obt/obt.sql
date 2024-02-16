WITH

    -- fact
    fct_points AS (
        SELECT * FROM {{ ref('fct_points') }}
    )

    -- dims

    , dim_matchups AS (
        SELECT * FROM {{ ref('dim_matchups') }}
    )

    , dim_members AS (
        SELECT * FROM {{ ref('dim_members') }}
    )

    , dim_players AS (
        SELECT * FROM {{ ref('dim_players') }}
    )

    , dim_stats AS (
        SELECT * FROM {{ ref('dim_stats') }}
    )

    , dim_teams AS (
        SELECT * FROM {{ ref('dim_teams') }}
    )

    , dim_time AS (
        SELECT * FROM {{ ref('dim_time') }}
    )

    -- obt
    -- join everything together
    -- except keys since they're just for joining
    -- ref = actual model
    -- relation_alias = alias (e.g., `fct` in `FROM fct_points fct`)
    -- except = columns to exclude
    , obt AS (
        SELECT
            {{ dbt_utils.star(from=ref('fct_points'), relation_alias='fct', except=[
                "matchup_key", "member_key", "player_key", "stat_key", "team_key", "time_key",
            ]) }}
            
            , {{ dbt_utils.star(from=ref('dim_matchups'), relation_alias='mat', except=[
                "matchup_key",
                "season_id"	, "scoring_period_id", 
                "schedule_id", "team_id",
            ]) }}
            
            , {{ dbt_utils.star(from=ref('dim_members'), relation_alias='mem', except=[
                "member_key",
                "season_id"	, "scoring_period_id",
            ]) }}

            , {{ dbt_utils.star(from=ref('dim_players'), relation_alias='plr', except=[
                "player_key",
                "season_id"	, "scoring_period_id",
                "player_id",
            ]) }}
            
            , {{ dbt_utils.star(from=ref('dim_stats'), relation_alias='sts', except=[
                "stat_key",
                "season_id"	, "scoring_period_id",
            ]) }}

            , {{ dbt_utils.star(from=ref('dim_teams'), relation_alias='tm', except=[
                "team_key",
                "season_id"	, "scoring_period_id",
            ]) }}

            , {{ dbt_utils.star(from=ref('dim_time'), relation_alias='t', except=[
                "time_key",
            ]) }}
        
        FROM fct_points fct
        
        LEFT JOIN dim_matchups mat
        ON fct.matchup_key = mat.matchup_key

        LEFT JOIN dim_members mem
        ON fct.member_key = mem.member_key

        LEFT JOIN dim_players plr
        ON fct.player_key = plr.player_key

        LEFT JOIN dim_stats sts
        ON fct.stat_key = sts.stat_key

        LEFT JOIN dim_teams tm
        ON fct.team_key = tm.team_key

        LEFT JOIN dim_time t
        ON fct.time_key = t.time_key
    )

    , lutu AS (
        SELECT * FROM obt
    )

SELECT * FROM lutu