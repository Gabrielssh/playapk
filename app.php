<?php
declare(strict_types=1);

const APPS_FILE = __DIR__ . '/apps.json';
function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, 'UTF-8'); }

$apps = file_exists(APPS_FILE) ? json_decode(file_get_contents(APPS_FILE), true) : [];
if (!is_array($apps)) $apps = [];

$id = (string)($_GET["id"] ?? "");
if ($id === "") { header("Location: index.php"); exit; }

$appFound = null;
foreach ($apps as $app) {
    if (($app["id"] ?? "") === $id) { $appFound = $app; break; }
}
if (!$appFound) { header("Location: index.php"); exit; }

$appName = (string)($appFound["nome"] ?? "App");
$appImg  = (string)($appFound["img"] ?? "");
$downloads = (int)($appFound["downloads"] ?? 0);

$downloadUrl = 'download.php?id=' . rawurlencode((string)($appFound["id"] ?? ""));
?>
<!doctype html>
<html lang="pt-br">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?php echo h($appName); ?> - Play Apk</title>
<style>
:root{--green:#00c853;--bg:#f4f6f8;--text:#111;--muted:#5f6368;--border:#e6e8eb;}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:var(--bg);color:var(--text);}
.topbar{position:sticky;top:0;background:var(--green);color:#fff;padding:12px 14px;display:flex;align-items:center;gap:12px;}
.topbar a{color:#fff;text-decoration:none;font-weight:900}
.container{max-width:860px;margin:0 auto;padding:14px;}
.panel{background:#fff;border:1px solid var(--border);border-radius:18px;padding:14px;}
.hero{display:flex;gap:14px;align-items:center;}
.icon{width:84px;height:84px;border-radius:18px;object-fit:cover;background:#eee;}
h1{margin:0;font-size:20px;}
.meta{margin-top:6px;color:var(--muted);font-size:13px}
.btn{display:block;text-align:center;text-decoration:none;border-radius:14px;padding:12px 14px;font-weight:900;font-size:14px;background:var(--green);color:#fff;width:100%;}
.note{margin-top:10px;color:var(--muted);font-size:12px;line-height:1.35}
</style>
</head>
<body>
<div class="topbar"><a href="index.php">← Voltar</a><div style="font-weight:900;">Play Apk</div></div>

<div class="container">
  <div class="panel">
    <div class="hero">
      <img class="icon" src="img/<?php echo rawurlencode($appImg); ?>" alt="">
      <div>
        <h1><?php echo h($appName); ?></h1>
        <div class="meta"><?php echo $downloads; ?> downloads</div>
      </div>
    </div>

    <div style="margin-top:14px;">
      <a class="btn" href="<?php echo h($downloadUrl); ?>" download>Instalar</a>
      <div class="note">Após baixar, toque na notificação do download para abrir o instalador.</div>
    </div>
  </div>
</div>
</body>
</html>
