<?php
declare(strict_types=1);

const APPS_FILE = __DIR__ . '/apps.json';
const APK_DIR   = __DIR__ . '/apks';

$apps = file_exists(APPS_FILE) ? json_decode(file_get_contents(APPS_FILE), true) : [];
if (!is_array($apps)) $apps = [];

$id = (string)($_GET["id"] ?? "");
if ($id === "") { http_response_code(400); exit("ID inválido"); }

foreach ($apps as &$app) {
    if (($app["id"] ?? "") === $id) {
        $apk  = (string)($app["apk"] ?? "");
        $file = APK_DIR . "/" . $apk;

        if (!is_file($file)) { http_response_code(404); exit("Arquivo não encontrado"); }

        $app["downloads"] = (int)($app["downloads"] ?? 0) + 1;
        file_put_contents(APPS_FILE, json_encode($apps, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT), LOCK_EX);

        header("X-Content-Type-Options: nosniff");
        header("Content-Type: application/vnd.android.package-archive");
        header("Content-Disposition: attachment; filename=\"" . basename($apk) . "\"");
        header("Content-Length: " . filesize($file));
        readfile($file);
        exit;
    }
}
http_response_code(404);
echo "App não encontrado";
