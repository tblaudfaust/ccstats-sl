# FreePBX objects to create (web UI, browser pane, after you sign in)

## Settings
- Asterisk SIP Settings > General: External Address = VPS IP, Local Networks = none needed (public IP on NIC), NAT = no,
  ICE Support = yes, STUN = stun.l.google.com:19302, RTP range 10000-20000, codecs: alaw, ulaw, g722, opus (WebRTC).
- Advanced Settings: HTTP(S) bind: enable TLS, port 8089, cert = pbx.DOMAIN (Certificate Manager, Let's Encrypt).
- Certificate Manager: Let's Encrypt cert for pbx.DOMAIN, set as default.
- Firewall: enabled, Responsive Firewall on for pjsip and WSS, office IP trusted.
- Call Recording: keep in /var/spool/asterisk/monitor; Backup & Restore job weekly to remote SFTP/S3.

## Connectivity
- Trunk `Africell` (pjsip): per operator questionnaire; max channels 30; Outbound CID main DID; Dialed manipulation rules.
- Trunk `Qcell` (pjsip): same.
- Outbound routes: as in docs/dialplan-sierra-leone.md.
- Inbound routes: one per DID -> Time Condition `Business hours`.

## Applications
- Time Group `Business hours`: Mon-Fri 08:00-17:00, Sat 09:00-13:00 (adjust).
- Time Condition `Business hours`: match -> IVR `Main menu`; no match -> Announcement `Closed` -> VM 1001.
- IVR `Main menu`: 1 -> Queue 600, 2 -> Queue 601, 0 -> ext 1001, timeout -> Queue 600.
- Queue 600 `Helpdesk`: strategy rrmemory, ring time 20, wrap-up 10s, max wait 300, join announcement, periodic position, hold music, record calls = force, agents dynamic (login *45, or Odoo click).
- Queue 601 `Sales`: same, agents 1021-1030.
- Feature codes: *45 queue toggle, *46 pause, recording *1.
- Announcements: welcome / closed (record via *77 or upload WAV 8kHz mono).
- Music on Hold: upload licensed/CC audio.

## Users
- UCP enabled for all agents (fallback webphone). Admin user for supervisor with Queue Reports.
