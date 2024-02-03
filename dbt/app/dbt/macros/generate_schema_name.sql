-- # Overview
-- overwrite default schema generation
-- https://discourse.getdbt.com/t/using-different-target-schemas-in-dbt/7732/5

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}