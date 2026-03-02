#!/bin/bash
# wait-for-it.sh — Wait for MySQL to be ready before proceeding
set -e

HOST="${1:-db}"
PORT="${2:-3306}"
TIMEOUT="${3:-60}"

echo "Waiting for MySQL at ${HOST}:${PORT}..."

start_time=$(date +%s)
while true; do
    if mysqladmin ping -h "$HOST" -P "$PORT" --silent 2>/dev/null; then
        echo "MySQL is ready!"
        exit 0
    fi

    current_time=$(date +%s)
    elapsed=$(( current_time - start_time ))
    if [ "$elapsed" -ge "$TIMEOUT" ]; then
        echo "ERROR: Timed out waiting for MySQL after ${TIMEOUT}s"
        exit 1
    fi

    sleep 2
done
