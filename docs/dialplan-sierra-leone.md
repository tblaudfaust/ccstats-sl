# Dial plan — Sierra Leone (+232)

National format: 0 + 8 digits (0yy xxxxxx). International: +232 yy xxxxxx. International access: 00.
Emergency: 019 (police), 999 (ambulance/fire), confirm with the operators that these pass over the trunk.

## Operator prefixes (2025 allocation, confirm with each operator before go-live)

| Operator | Mobile NDCs |
|---|---|
| Africell | 30, 33, 77, 80, 88, 90, 99 |
| Qcell | 31, 32, 34 |
| Orange | 72, 73, 74, 75, 76, 78, 79 |
| Sierratel fixed | 22 (Freetown), 52 (Makeni/Koidu) |

Note: 32 was historically the Bo/Kenema fixed prefix and now appears in Qcell's range. Ask Qcell.

## Outbound routes (Connectivity > Outbound Routes), in priority order

1. Route "Emergency" — patterns `019`, `999` — trunks: Africell, Qcell. Mark as Emergency route.
2. Route "Africell-onnet" — patterns (match, prepend nothing):
   `030XXXXXX`, `033XXXXXX`, `077XXXXXX`, `080XXXXXX`, `088XXXXXX`, `090XXXXXX`, `099XXXXXX`
   plus `+232` forms: prefix `+232` | match `30XXXXXX` ... via pattern `+23230XXXXXX` with prepend `0` and prefix `+232`.
   Trunk sequence: Africell, then Qcell (failover).
3. Route "Qcell-onnet" — `031XXXXXX`, `032XXXXXX`, `034XXXXXX` and `+232` forms. Trunk sequence: Qcell, then Africell.
4. Route "SL-national" — `0XXXXXXXX` and `+232XXXXXXXX` (prefix `+232` → prepend `0`). Trunk: whichever operator quotes the cheaper off-net rate, other as failover.
5. Route "International" — `00.` and `+.` with PIN set or restricted to a supervisor group. Trunk: cheaper international rate.

Trunk "Dialed Number Manipulation Rules" convert the number to the format the operator asked for in
the questionnaire (item 5), for example strip 0, prepend 232.

## Inbound

One inbound route per DID (Connectivity > Inbound Routes) → Time Condition "Business hours" →
IVR "Main menu" (1 = Helpdesk queue 600, 2 = Sales queue 601, 0 = operator ext 1001) /
closed → announcement + voicemail 1001.
