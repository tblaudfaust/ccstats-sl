<?php
/**
 * Creates agent extensions 1001..1030 (pjsip, WebRTC enabled, voicemail on) via the FreePBX API.
 * Run on the VPS as root:  php /root/freepbx-contact-center/freepbx/create-extensions.php [start] [count]
 * Writes the generated secrets to /root/agent-extensions.csv (chmod 600) for entry into Odoo.
 * Before first use I verify Core::processQuickCreate() exists on this FreePBX build.
 */
$start = (int)($argv[1] ?? 1001);
$count = (int)($argv[2] ?? 30);

$bootstrap_settings['freepbx_auth'] = false;
$restrict_mods = false;
include '/etc/freepbx.conf';   // pulls in bootstrap.php and \FreePBX

$core = \FreePBX::Core();
if (!method_exists($core, 'processQuickCreate')) {
    fwrite(STDERR, "Core::processQuickCreate not available on this build, stop.\n");
    exit(1);
}

$out = fopen('/root/agent-extensions.csv', 'w');
chmod('/root/agent-extensions.csv', 0600);
fputcsv($out, ['extension', 'name', 'secret']);

for ($i = 0; $i < $count; $i++) {
    $ext  = (string)($start + $i);
    $name = "Agent {$ext}";
    if ($core->getDevice($ext)) { echo "skip {$ext} (exists)\n"; continue; }
    $secret = bin2hex(random_bytes(12));
    $ok = $core->processQuickCreate('pjsip', $ext, $name, '', '', 'yes', [
        'secret'            => $secret,
        'vm_password'       => substr(str_shuffle('123456789'), 0, 4),
        'callwaiting_enable'=> 'DISABLED',
        'recording_in_external'  => 'force',
        'recording_out_external' => 'force',
    ]);
    if ($ok === false) { echo "FAILED {$ext}\n"; continue; }
    // WebRTC transport/defaults so the Odoo browser phone can register over WSS 8089
    $core->setDeviceSetting($ext, 'webrtc', 'yes') ?? null;
    fputcsv($out, [$ext, $name, $secret]);
    echo "created {$ext}\n";
}
fclose($out);
needreload();
echo "done; run: fwconsole reload\n";
