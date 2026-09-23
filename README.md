# FreePBX contact center on Hostinger (Sierra Leone)

Target: one Hostinger KVM 4 running FreePBX 17 (Debian 12 template) plus Odoo 18 Community in Docker,
with Africell and Qcell SIP trunks, 30 concurrent calls, agents on a browser softphone inside Odoo.

## Architecture

```
Africell SIP  ──┐                                   ┌── Agents (browser: Odoo + voip_oca WebRTC phone)
Qcell SIP     ──┴─ UDP 5060 ─► FreePBX 17 / Asterisk ◄─ WSS 8089 ┘
                               │  queues, IVR, recording, CDR
                               │  Apache :443   ccstats.statistics.sl       (FreePBX admin UI, UCP)
                               │  Apache :8443  ccstats.statistics.sl:8443  ─► Docker: Odoo 18 + Postgres 16
```

Odoo does not talk to Asterisk over AMI. Each agent's browser registers to FreePBX as a
WebRTC extension through the OCA `voip_oca` module, which gives click-to-call, inbound screen pop
with contact match, and a call log. Everything is AGPL/GPL, no license fees.

## What you do (once)

1. hPanel > VPS > buy/choose **KVM 4**, location **Netherlands** or **United Kingdom** (shortest path to the ACE cable landing in Freetown).
2. OS & Panel > Operating System > **Application** tab > **Debian 12 with FreePBX**. When asked for an SSH key, paste the key in `docs/ssh-public-key.txt`. If you missed it, add it under VPS > Settings > SSH keys and reinstall, or paste it into `/root/.ssh/authorized_keys` from the hPanel browser terminal.
3. Open `http://<VPS-IP>` and finish the FreePBX wizard (admin user, your email, timezone Africa/Freetown).
4. DNS: `ccstats.statistics.sl` → 187.77.98.217 (done).
5. In hPanel > VPS > Security > Firewall create the rules in `docs/hostinger-firewall.md`.
6. Send `docs/sip-trunk-request.md` to Africell and Qcell business teams.
7. VPS: root@187.77.98.217, office IP 129.224.205.159.

## What I do (over SSH with the key)

| Step | File | Result |
|---|---|---|
| 1 | `scripts/01-harden.sh` | timezone, updates, fail2ban, key-only SSH, FreePBX firewall trust for your office |
| 2 | `scripts/02-odoo-stack.sh` | Docker, Odoo 18 + Postgres, OCA addons, Apache vhost on 8443 + Let's Encrypt |
| 3 | `freepbx/create-extensions.php` | 30 agent extensions 1001-1030, WebRTC enabled |
| 4 | browser pane, you sign in | trunks, inbound/outbound routes, queues, IVR, time conditions, recording |
| 5 | Odoo UI | PBX server, per-user SIP credentials, CRM + Helpdesk apps |

Trunk creation waits on the operators' answers (auth type, IP, codecs, DIDs).
