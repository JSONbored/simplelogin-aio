#!/command/with-contenv bash
# shellcheck shell=bash
# shellcheck disable=SC2154
set -euo pipefail

echo "Configuring Postfix MTA routing..."

DB_URI_VALUE="${DB_URI:-$(cat /var/run/s6/container_environment/DB_URI 2>/dev/null || true)}"

parse_postgres_uri() {
	DB_URI_TO_PARSE="$1" python3 <<'PY'
import os
from urllib.parse import urlparse, unquote

uri = os.environ["DB_URI_TO_PARSE"]
parsed = urlparse(uri)

if parsed.scheme not in {"postgresql", "postgres"}:
    raise SystemExit(f"Unsupported DB_URI scheme for Postfix configuration: {parsed.scheme or '<missing>'}")

if not parsed.hostname or not parsed.path or parsed.path == "/":
    raise SystemExit("DB_URI must include host and database name for Postfix configuration")

username = parsed.username or ""
password = parsed.password or ""
database = parsed.path.lstrip("/")

if not username or not password or not database:
    raise SystemExit("DB_URI must include username, password, and database name for Postfix configuration")

host = parsed.hostname
port = f":{parsed.port}" if parsed.port else ""

print(unquote(username))
print(unquote(password))
print(f"{host}{port}")
print(unquote(database))
PY
}

if [[ -f /appdata/postgres/.sl_internal_pass ]]; then
	PG_PASS=$(cat /appdata/postgres/.sl_internal_pass)
	PG_USER="simplelogin"
	PG_HOST="127.0.0.1"
	PG_DB="simplelogin"
elif [[ -n ${DB_URI_VALUE} ]]; then
	parsed_db_uri_output="$(parse_postgres_uri "${DB_URI_VALUE}")"
	mapfile -t parsed_db_uri <<<"${parsed_db_uri_output}"
	PG_USER="${parsed_db_uri[0]}"
	PG_PASS="${parsed_db_uri[1]}"
	PG_HOST="${parsed_db_uri[2]}"
	PG_DB="${parsed_db_uri[3]}"
else
	echo "Unable to determine PostgreSQL settings for Postfix."
	exit 1
fi

cat >/etc/postfix/pgsql-relay-domains.cf <<EOF
user = ${PG_USER}
password = ${PG_PASS}
hosts = ${PG_HOST}
dbname = ${PG_DB}
query = SELECT domain FROM custom_domain WHERE domain = '%s' AND verified = true
    UNION SELECT '%s' WHERE '%s' = '${EMAIL_DOMAIN}' LIMIT 1;
EOF

cat >/etc/postfix/pgsql-transport-maps.cf <<EOF
user = ${PG_USER}
password = ${PG_PASS}
hosts = ${PG_HOST}
dbname = ${PG_DB}
query = SELECT 'smtp:127.0.0.1:20381' FROM custom_domain WHERE domain = '%s' AND verified = true
    UNION SELECT 'smtp:127.0.0.1:20381' WHERE '%s' = '${EMAIL_DOMAIN}' LIMIT 1;
EOF

chmod 640 /etc/postfix/pgsql-*.cf
chown postfix:postfix /etc/postfix/pgsql-*.cf

if [[ ! -f /etc/ssl/private/ssl-cert-snakeoil.key ]] || [[ ! -f /etc/ssl/certs/ssl-cert-snakeoil.pem ]]; then
	mkdir -p /etc/ssl/private /etc/ssl/certs
	openssl req -x509 -nodes -days 3650 -subj "/CN=mail.${EMAIL_DOMAIN}" \
		-newkey rsa:2048 \
		-keyout /etc/ssl/private/ssl-cert-snakeoil.key \
		-out /etc/ssl/certs/ssl-cert-snakeoil.pem >/dev/null 2>&1
fi

# Debian runs Postfix services in a chroot. Refresh its resolver and public
# trust roots on every start, including when Docker assigns new DNS settings.
queue_dir="$(postconf -h queue_directory)"
install -d "${queue_dir}/etc" "${queue_dir}/etc/ssl/certs"
for resolver_file in resolv.conf hosts nsswitch.conf; do
	install -m 0644 "/etc/${resolver_file}" "${queue_dir}/etc/${resolver_file}"
done
install -m 0644 /etc/ssl/certs/ca-certificates.crt "${queue_dir}/etc/ssl/certs/ca-certificates.crt"
postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"

postconf -e "compatibility_level = 2"
postconf -e "myhostname = mail.${EMAIL_DOMAIN}"
postconf -e "mydomain = ${EMAIL_DOMAIN}"
postconf -e "myorigin = ${EMAIL_DOMAIN}"
postconf -e "mydestination ="
postconf -e "inet_interfaces = all"
postconf -e "alias_maps = hash:/etc/aliases"
postconf -e "relay_domains = pgsql:/etc/postfix/pgsql-relay-domains.cf"
postconf -e "transport_maps = pgsql:/etc/postfix/pgsql-transport-maps.cf"
postconf -e "mynetworks = 127.0.0.0/8 [::1]/128"
postconf -e "smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem"
postconf -e "smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key"
postconf -e "smtp_tls_security_level = may"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtpd_delay_reject = yes"
postconf -e "smtpd_helo_required = yes"
postconf -e "smtpd_helo_restrictions = permit_mynetworks,reject_non_fqdn_helo_hostname,reject_invalid_helo_hostname,permit"
postconf -e "smtpd_sender_restrictions = permit_mynetworks,reject_non_fqdn_sender,reject_unknown_sender_domain,permit"
postconf -e "smtpd_recipient_restrictions = reject_unauth_pipelining,reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_mynetworks,reject_unauth_destination,permit"

echo "Applying SMTP relay configuration..."
: >/etc/postfix/sasl_passwd

case "${RELAY_MODE:-direct}" in
direct)
	postconf -X "relayhost"
	;;
brevo)
	postconf -e "relayhost = [smtp-relay.brevo.com]:587"
	echo "[smtp-relay.brevo.com]:587 ${BREVO_USERNAME}:${BREVO_PASSWORD}" >/etc/postfix/sasl_passwd
	;;
protonmail)
	postconf -e "relayhost = [smtp.protonmail.ch]:587"
	echo "[smtp.protonmail.ch]:587 ${SUPPORT_EMAIL}:${PROTONMAIL_TOKEN}" >/etc/postfix/sasl_passwd
	;;
gmail)
	postconf -e "relayhost = [smtp.gmail.com]:587"
	echo "[smtp.gmail.com]:587 ${GMAIL_USERNAME}:${GMAIL_APP_PASSWORD}" >/etc/postfix/sasl_passwd
	;;
mailgun)
	postconf -e "relayhost = [smtp.mailgun.org]:587"
	echo "[smtp.mailgun.org]:587 ${MAILGUN_USERNAME}:${MAILGUN_PASSWORD}" >/etc/postfix/sasl_passwd
	;;
custom)
	postconf -e "relayhost = ${CUSTOM_RELAYHOST}"
	echo "${CUSTOM_RELAYHOST} ${CUSTOM_USERNAME}:${CUSTOM_PASSWORD}" >/etc/postfix/sasl_passwd
	;;
*)
	echo "Unsupported RELAY_MODE: ${RELAY_MODE:-direct}" >&2
	exit 1
	;;
esac

if [[ ${RELAY_MODE:-direct} != "direct" ]]; then
	postconf -e "smtp_sasl_auth_enable = yes"
	postconf -e "smtp_sasl_security_options = noanonymous"
	postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
	postconf -e "smtp_tls_security_level = secure"
	postmap /etc/postfix/sasl_passwd
	chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
fi

newaliases >/dev/null 2>&1 || true
echo "Postfix configuration complete."
