#!/usr/bin/env bash
# Run as root on the VPS. Installs Docker, deploys Odoo 18 CE + Postgres 16 with OCA addons,
# and publishes it as https://crm.DOMAIN through the existing FreePBX Apache.
# Usage: bash 02-odoo-stack.sh crm.example.com admin@example.com
set -euo pipefail
CRM_HOST="${1:?usage: 02-odoo-stack.sh <crm.hostname> <letsencrypt-email>}"
LE_EMAIL="${2:?}"
STACK=/opt/odoo-stack
SRC="$(cd "$(dirname "$0")/.." && pwd)"   # repo copy rsynced to the server

echo "== Docker (official apt repo)"
if ! command -v docker >/dev/null; then
  apt-get update -q
  apt-get install -y -q ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -q
  apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

echo "== stack files"
mkdir -p "$STACK"
rsync -a "$SRC/odoo/" "$STACK/"
cd "$STACK"

echo "== OCA addons (18.0)"
mkdir -p addons
for repo in connector-telephony helpdesk partner-contact server-tools web; do
  if [ ! -d "addons/$repo" ]; then
    git clone --depth 1 -b 18.0 "https://github.com/OCA/$repo.git" "addons/$repo"
  fi
done
for m in connector-telephony/voip_oca connector-telephony/base_phone helpdesk/helpdesk_mgmt; do
  [ -d "addons/$m" ] || echo "WARNING: addons/$m missing on branch 18.0, check OCA"
done

echo "== secrets"
if [ ! -f .env ]; then
  cat > .env <<CFG
POSTGRES_PASSWORD=$(openssl rand -hex 24)
ODOO_MASTER_PASSWORD=$(openssl rand -hex 24)
CRM_HOST=${CRM_HOST}
CFG
  chmod 600 .env
fi
. ./.env
sed -i "s|^admin_passwd = .*|admin_passwd = ${ODOO_MASTER_PASSWORD}|" config/odoo.conf

echo "== build + initial database"
docker compose build
docker compose up -d db
sleep 8
if ! docker compose run --rm odoo odoo -d crm --db_host=db --db_user=odoo --db_password="$POSTGRES_PASSWORD" \
     --stop-after-init -i base,contacts,crm,calendar,base_phone,voip_oca,helpdesk_mgmt 2>&1 | tail -n 20; then
  echo "initial install reported errors, inspect above"
fi
docker compose up -d

echo "== Apache vhost + TLS"
apt-get install -y -q certbot
a2enmod proxy proxy_http proxy_wstunnel headers ssl rewrite >/dev/null
mkdir -p /var/www/acme
sed "s/CRM_HOST/${CRM_HOST}/g" apache/crm-http.conf > /etc/apache2/sites-available/crm-http.conf
a2ensite crm-http >/dev/null
apache2ctl configtest && systemctl reload apache2
certbot certonly --webroot -w /var/www/acme -d "$CRM_HOST" -m "$LE_EMAIL" --agree-tos --non-interactive
sed "s/CRM_HOST/${CRM_HOST}/g" apache/crm-https.conf > /etc/apache2/sites-available/crm-https.conf
a2ensite crm-https >/dev/null
apache2ctl configtest && systemctl reload apache2
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-apache.sh <<'HOOK'
#!/bin/sh
systemctl reload apache2
HOOK
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-apache.sh

echo "== done: https://${CRM_HOST}  (master password in ${STACK}/.env)"
