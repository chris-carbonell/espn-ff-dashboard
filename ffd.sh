#!/usr/bin/env bash

# Overview
# helper script for often used commands

# Quickstart
# * build with `./ffd.sh -b`
# * get dbt container's terminal with `./ffd.sh -dit`
# * extract initial data with `./ffd.sh -ed`

# set defaults

BUILD_PROJECT=false
DOWN_PROJECT=false
GET_DBT=false
EXTRACT_DATA=false

# parse args

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--build)
      BUILD_PROJECT=true
      shift # past argument
      ;;
    -d|--down)
      DOWN_PROJECT=true
      shift # past argument
      ;;
    -dit|--dbt-terminal)
      GET_DBT=true
      shift # past argument
      ;;
    -ed|--extract-data)
      EXTRACT_DATA=true
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# build project
if $BUILD_PROJECT ; then
    echo "building with docker compose"
    docker-compose up -d --build
fi

# down project
if $DOWN_PROJECT ; then
    echo "stopping and removing with docker compose"
    docker-compose down
fi

# get dbt terminal
if $GET_DBT ; then
    echo "entering dbt terminal"
    docker exec -it ffd-dbt /bin/bash
fi

# extracxt data
if $EXTRACT_DATA ; then
    echo "extracting initial data"
    docker exec -it ffd-dbt python /home/update/extract_and_load/extract_and_load_initial.py
fi