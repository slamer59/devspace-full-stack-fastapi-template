#!/bin/bash

set -e

echo "Starting FastAPI development server..."

# In development mode, start FastAPI directly without waiting for database
# The application will handle database connections lazily
echo "Skipping database pre-check in development mode..."
echo "FastAPI will connect to database on first request"

# Run the FastAPI server in development mode with hot reloading
echo "Starting FastAPI server with hot reloading..."
exec fastapi dev --host 0.0.0.0 --port 8000 app/main.py