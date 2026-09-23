# SIP trunk request — send to Africell SL and Qcell SL business/enterprise teams

Subject: Request for SIP trunk (IP-PBX interconnect), 30 concurrent channels

We are deploying an IP-PBX (Asterisk / FreePBX 17) hosted on a public static IP and would like a
SIP trunk from your network. Please provide a quotation and the technical parameters below.

Requirements
- 30 concurrent channels (expandable to 60)
- Block of DIDs (at least 5 numbers) for inbound; a short code if available
- Outbound caller ID set to our main DID
- Static IP authentication preferred (our PBX IP: VPS_IP); registration-based is acceptable

Technical parameters we need from you
1. Signaling: SIP server IP/FQDN, port, transport (UDP/TCP/TLS)
2. Authentication: IP-based (whitelist VPS_IP) or username/password registration
3. Codecs supported and preferred (we prefer G.711 A-law; please state if only G.729)
4. DTMF method (RFC 2833 / SIP INFO / inband)
5. Number format expected in the To/Request-URI for national calls (0XXXXXXXX or 232XXXXXXXX or +232...)
6. Number format sent to us in the From header on inbound calls
7. Media IP range (RTP) so we can whitelist it
8. SIP OPTIONS keepalive support, and session timers requirements
9. Concurrent-call limit and per-second call setup limit
10. Billing: on-net vs off-net rates, international rates, and whether on-net calls to your subscribers are discounted
11. Emergency numbers routing (019 / 999) via the trunk

If SIP trunking is not offered, please quote a GSM gateway arrangement (multi-SIM, 8 to 16 channels)
and the on-net tariff applicable.

Contact: NAME, PHONE, EMAIL
