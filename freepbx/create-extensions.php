<?php
/**
 * Creates agent extensions (pjsip, WebRTC enabled, recording forced, voicemail on) via the
 * FreePBX Core API, then reloads. Run on the PBX as root:
 *   php create-extensions.php [start=1001] [count=30]
 * Secrets are written to /root/agent-extensions.csv (mode 600) for entry into Odoo user preferences.
 * Verified against FreePBX 17.0.33: Core::processQuickCreate($tech, $extension, $data).
 */
$start = (int)($argv[1] ?? 1001);
$count = (int)($argv[2] ?? 30);

$bootstrap_settings['freepbx_auth'] = false;
$restrict_mods = false;
include '/etc/freepbx.conf';   // bootstraps \FreePBX

$core = \FreePBX::Core();
$db   = \FreePBX::Database();

$csv = '/root/agent-extensions.csv';
$out = fopen($csv, 'a');
chmod($csv, 0600);
if (filesize($csv) === 0) { fputcsv($out, ['extension', 'name', 'secret', 'vm_pin']); }

for ($i = 0; $i < $count; $i++) {
    $ext  = (string)($start + $i);
    $name = "Agent {$ext}";
    if ($core->getDevice($ext)) { echo "skip {$ext} (exists)\n"; continue; }
    $secret = bin2hex(random_bytes(12));
    $vmpin  = (string)random_int(1000, 9999);
    $res = $core->processQuickCreate('pjsip', $ext, [
        'name'                   => $name,
        'secret'                 => $secret,
        'outboundcid'            => '',
        'max_contacts'           => 2,          // browser phone + a fallback softphone
        'callwaiting'            => 'disabled', // agents take one call at a time
        'recording_in_external'  => 'force',
        'recording_out_external' => 'force',
        'recording_in_internal'  => 'dontcare',
        'recording_out_internal' => 'dontcare',
        // voicemail module quick-create hook
        'vm'                     => 'yes',
        'vmpwd'                  => $vmpin,
        'email'                  => '',
    ]);
    if (empty($res['status'])) { echo "FAILED {$ext}: " . ($res['message'] ?? '?') . "\n"; continue; }
    // WebRTC defaults (Asterisk webrtc=yes => AVPF, ICE, DTLS-SRTP, rtcp-mux, auto cert)
    $db->prepare("UPDATE sip SET data='yes' WHERE id=? AND keyword='webrtc'")->execute([$ext]);
    fputcsv($out, [$ext, $name, $secret, $vmpin]);
    echo "created {$ext}\n";
}
fclose($out);
needreload();
echo "done; secrets in {$csv}; now: fwconsole reload\n";
