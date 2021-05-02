#!/usr/bin/env bash
set -euo pipefail

echo "Running phoenix-entrypoint.sh..."

while ! pg_isready -q -h $PGHOST -p $PGPORT -U $PGUSER
do
  echo "$(date) - waiting for database container to start"
  sleep 1
done

if [[ -z `psql -Atqc "\\list $PGDATABASE"` ]]; then
  echo "Database $PGDATABASE does not exist. Creating..."
  createdb $PGDATABASE
  echo "Database $PGDATABASE created."
fi

echo "Running migrations..."
bin/deer_storage eval "DeerStorage.Release.migrate"

echo "Starting application..."
exec bin/deer_storage start
