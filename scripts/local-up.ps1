# Runs the Odoo stack on Docker Desktop with the OCA addons. Idempotent.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location "$root\odoo"
New-Item -ItemType Directory -Force addons | Out-Null
foreach ($repo in @("connector-telephony","helpdesk","partner-contact","server-tools","web")) {
  if (-not (Test-Path "addons\$repo")) { git clone --depth 1 -b 18.0 "https://github.com/OCA/$repo.git" "addons\$repo" }
}
if (-not (Test-Path .env)) {
  $pw = -join ((48..57 + 97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
  "POSTGRES_PASSWORD=$pw`nODOO_MASTER_PASSWORD=localdev`nCRM_HOST=localhost" | Set-Content -Encoding ascii .env
}
$env:COMPOSE_FILE = "docker-compose.yml;docker-compose.local.yml"
docker compose build
docker compose up -d db
Start-Sleep 8
$pg = (Get-Content .env | Where-Object { $_ -like "POSTGRES_PASSWORD=*" }).Split("=")[1]
docker compose run --rm odoo odoo -d crm --db_host=db --db_user=odoo --db_password=$pg --stop-after-init -i base,contacts,crm,calendar,base_phone,voip_oca,helpdesk_mgmt
docker compose up -d
Write-Host "Odoo: http://localhost:8069  (db crm, login admin / admin — change it)"
