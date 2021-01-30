echo "Running entrypoint.sh..."

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
bin/pjeski eval "Pjeski.Release.migrate"

echo "Starting application..."
exec bin/pjeski start
