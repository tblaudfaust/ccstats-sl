# Moving the local build to the Hostinger VPS

## Odoo (Docker Desktop -> VPS Docker)
1. Local:  `docker compose exec db pg_dump -U odoo -Fc crm > crm.dump`
           `docker compose cp odoo:/var/lib/odoo/filestore/crm ./filestore-crm`
2. Copy `crm.dump` and `filestore-crm/` to the VPS (`scp`/`rsync` to /opt/odoo-stack/migrate/).
3. VPS, after 02-odoo-stack.sh (skip its `-i` install step or drop the db it created):
   `docker compose exec -T db dropdb -U odoo crm; docker compose exec -T db createdb -U odoo crm`
   `docker compose exec -T db pg_restore -U odoo -d crm < migrate/crm.dump`
   `docker compose cp migrate/filestore-crm odoo:/var/lib/odoo/filestore/crm` then `docker compose restart odoo`
4. In Odoo: Settings > Technical > PBX Servers: change the websocket URL from the local FreePBX to wss://pbx.DOMAIN:8089/ws.
   Also update Settings > General > web.base.url to https://crm.DOMAIN.

## FreePBX (local VM/container -> Hostinger template)
1. Local FreePBX: Admin > Backup & Restore > create backup "full" (all modules, no recordings), download the .tar.gz.
2. VPS FreePBX 17 (fresh from template, after the wizard): Backup & Restore > Restore > upload the file > restore.
   The restore replaces extensions, trunks, routes, queues, IVRs, time conditions, recordings settings and certificates settings.
3. Post-restore on the VPS: Asterisk SIP Settings > External Address = VPS IP; Certificate Manager > issue Let's Encrypt for
   pbx.DOMAIN and re-select it in Advanced Settings (HTTPS 8089) and SIP TLS; Firewall > re-trust office IP; `fwconsole reload`.
4. Trunks: local placeholders get their real IP/credentials from the operators' answers, then re-test with one extension.
