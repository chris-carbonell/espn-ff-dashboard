# Overview
document design decisions

# Goals
* adhere to dbt best practices<br>https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview
    * staging = creates atomic building blocks from source
    * intermediate = prepares staging models for use in mart
    * marts = semantic layer (e.g.,, star schema and OBT)
* incremental loads
* star schema feeds OBT

# FAQs
1. Why prefix schemas with letters?<br>I wanted to have the listed alphabetically. Numbers (e.g., "01_stg") would've worked too but, then, I'd have to use double quotes to use those schema names in SQL.