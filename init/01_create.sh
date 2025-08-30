#!/bin/bash
set -e

echo 'Running Postgres Initialization script'

echo ""
echo "Creating Database ${APP_DB_NAME}"
echo ""

export PGPASSWORD=${POSTGRES_PASSWORD};
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
  CREATE USER ${APP_DB_USER} WITH PASSWORD '${APP_DB_PASS}';
  CREATE DATABASE ${APP_DB_NAME};
  GRANT ALL PRIVILEGES ON DATABASE ${APP_DB_NAME} TO ${APP_DB_USER};
  \c ${APP_DB_NAME};
  GRANT ALL PRIVILEGES ON SCHEMA public TO ${APP_DB_USER};
  GRANT pg_read_server_files TO ${APP_DB_USER};
  GRANT pg_read_server_files TO ${APP_DB_USER};
EOSQL

echo ""
echo 'Finished Postgres Initialization script'
echo ""
