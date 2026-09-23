# hPanel firewall rules (VPS > Security > Firewall)

Create one firewall, attach it to the VPS, add these rules. Replace the placeholders.

| Action | Protocol | Port | Source | Note |
|---|---|---|---|---|
| Accept | TCP | 22 | 129.224.205.159/32 | SSH (add a second rule for any other admin IP) |
| Accept | TCP | 80 | any | Let's Encrypt HTTP challenge, redirects to 443 |
| Accept | TCP | 443 | any | FreePBX admin + UCP at https://ccstats.statistics.sl |
| Accept | TCP | 8443 | any | Odoo CRM at https://ccstats.statistics.sl:8443 |
| Accept | UDP | 5060 | AFRICELL_SBC_IP/32 | trunk signaling, one rule per operator IP |
| Accept | UDP | 5060 | QCELL_SBC_IP/32 | |
| Accept | TCP | 8089 | any | WebRTC WSS for agents (rate limited by FreePBX firewall) |
| Accept | UDP | 10000-20000 | any | RTP media |
| Drop | any | any | any | default |

Do not open 5060 to "any". Every open SIP port on the internet receives brute force within minutes.
If an operator uses port 5080 or TCP, change the rule to match their spec.
