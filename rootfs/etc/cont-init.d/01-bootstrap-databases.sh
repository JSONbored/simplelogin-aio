#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail
# trunk-ignore(shellcheck/SC1091)
source /etc/simplelogin-aio/env-helpers.sh

echo "Checking internal database requirements..."

chmod 755 /appdata
mkdir -p /appdata/postgres /appdata/redis /appdata/dkim /appdata/sl/upload /pgp /custom-assets /run/postgresql
chown -R redis:redis /appdata/redis
chown -R postgres:postgres /appdata/postgres /run/postgresql
chown -R simplelogin:simplelogin /appdata/sl /pgp /custom-assets
chmod 700 /appdata/sl
chmod 700 /appdata/postgres /appdata/redis /pgp
chmod 700 /pgp

rm -rf /code/static/upload
ln -sfn /appdata/sl/upload /code/static/upload

DB_URI_VALUE="${DB_URI-}"
if [[ -z ${DB_URI_VALUE} ]]; then
	echo "No external DB_URI provided. Bootstrapping internal PostgreSQL..."

	if [[ ! -f "/appdata/postgres/PG_VERSION" ]]; then
		echo "Initializing bare Postgres cluster..."
		PG_BIN_DIR="$(find /usr/lib/postgresql -mindepth 2 -maxdepth 2 -type d -name bin | sort | head -n 1)"
		if [[ -z ${PG_BIN_DIR} ]]; then
			echo "Unable to locate PostgreSQL binaries under /usr/lib/postgresql."
			exit 1
		fi
		su -s /bin/bash postgres -c "${PG_BIN_DIR}/initdb --encoding=UTF8 --locale=C.UTF-8 --auth-local=peer --auth-host=scram-sha-256 -D /appdata/postgres"

		INTERNAL_PG_PASS=$(openssl rand -hex 24)
		printf '%s\n' "${INTERNAL_PG_PASS}" >/appdata/postgres/.sl_internal_pass
		chown postgres:postgres /appdata/postgres/.sl_internal_pass

		su -s /bin/bash postgres -c "${PG_BIN_DIR}/pg_ctl -D /appdata/postgres -o \"-c listen_addresses='127.0.0.1'\" -w start"
		su -s /bin/bash postgres -c "psql postgres <<'SQL'
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'simplelogin') THEN
        CREATE ROLE simplelogin LOGIN PASSWORD '${INTERNAL_PG_PASS}';
    ELSE
        ALTER ROLE simplelogin WITH PASSWORD '${INTERNAL_PG_PASS}';
    END IF;
END
\$\$;
SQL"
		su -s /bin/bash postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_database WHERE datname='simplelogin'\" | grep -qx 1 || createdb -O simplelogin simplelogin"
		su -s /bin/bash postgres -c "${PG_BIN_DIR}/pg_ctl -D /appdata/postgres -m fast -w stop"
	fi

	INTERNAL_PG_PASS=$(cat /appdata/postgres/.sl_internal_pass)
	DB_URI_VALUE="postgresql://simplelogin:${INTERNAL_PG_PASS}@127.0.0.1:5432/simplelogin"
fi

REDIS_URL_VALUE="${REDIS_URL:-redis://127.0.0.1:6379/0}"

sync_env_value "DB_URI" "${DB_URI_VALUE}"
sync_env_value "REDIS_URL" "${REDIS_URL_VALUE}"
