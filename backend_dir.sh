#!/usr/bin/env bash
set -e

# App package
mkdir -p app/{core,api/{v1,v2},models,schemas,services,db,utils,tests}

# API dependencies file
touch app/api/deps.py

# Main entrypoint
touch app/main.py

# Scripts and migrations
mkdir -p scripts
mkdir -p alembic/versions

# Docker & configuration
touch Dockerfile docker-compose.yml requirements.txt .env README.md

echo "Directory structure created."

