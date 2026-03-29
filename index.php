<?php
declare(strict_types=1);

const APPS_FILE = __DIR__ . '/apps.json';
function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, 'UTF-8'); }

$apps = file_exists(APPS_FILE) ? json_decode(file_get_contents(APPS_FILE), true) : [];
if (!is_array($apps)) $apps = [];

$q = trim((string)($_GET["q"] ?? ""));
$appsFiltered = $apps;

if ($q !== "") {
    $appsFiltered = array_values(array_filter($apps, function($app) use ($q) {
        return mb_stripos((string)($app["nome"] ?? ""), $q) !== false;
    }));
}

usort($appsFiltered, fn($a,$b) => (int)($b["downloads"] ?? 0) <=> (int)($a["downloads"] ?? 0));
?>
<!doctype html>
<html lang="pt-br">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Play Apk</title>
<style>
:root{--green:#00c853;--bg:#f4f6f8;--text:#111;--muted:#5f6368;--card:#fff;--border:#e6e8eb;}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:var(--bg);color:var(--text);}
.topbar{position:sticky;top:0;background:var(--green);color:#fff;padding:12px 14px;display:flex;align-items:center;justify-content:space-between;}
.brand{font-weight:900}
.container{max-width:980px;margin:0 auto;padding:14px;}
.search{display:flex;gap:10px;align-items:center;background:#fff;border:1px solid var(--border);padding:10px 12px;border-radius:14px;}
.search input{border:0;outline:0;width:100%;font-size:14px;}
.section-title{margin:14px 0 10px;font-size:13px;color:var(--muted);font-weight:900;text-transform:uppercase;letter-spacing:.4px;}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(270px,1fr));gap:12px;}
.card{background:var(--card);border:1px solid var(--border);border-radius:18px;padding:12px;display:flex;gap:12px;}
.icon{width:64px;height:64px;border-radius:16px;object-fit:cover;background:#eee;}
h3{margin:0;font-size:16px;}
.meta{margin-top:4px;color:var(--muted);font-size:12px;}
.btn{border:0;cursor:pointer;border-radius:12px;padding:10px 12px;font-weight:900;font-size:13px;}
.btn-install{background:var(--green);color:#fff;width:100%;}
a.clean{color:inherit;text-decoration:none;}
.note{margin-top:10px;color:var(--muted);font-size:12px}
</style>
</head>
<body>
<div class="topbar"><div class="brand">Play Apk</div></div>

<div class="container">
  <form class="search" method="GET">
    <input name="q" value="<?php echo h($q); ?>" placeholder="Pesquisar apps..." />
    <button class="btn" type="submit" style="background:#111;color:#fff;">Buscar</button>
  </form>

  <div class="section-title">Apps</div>

  <?php if (!$appsFiltered): ?>
    <div class="note">Nenhum app cadastrado.</div>
  <?php endif; ?>

  <div class="grid">
    <?php foreach ($appsFiltered as $app): ?>
      <div class="card">
        <a class="clean" href="app.php?id=<?php echo rawurlencode((string)($app["id"] ?? "")); ?>">
          <img class="icon" src="img/<?php echo rawurlencode((string)($app["img"] ?? "")); ?>" alt="">
        </a>

        <div style="flex:1;min-width:0;">
          <a class="clean" href="app.php?id=<?php echo rawurlencode((string)($app["id"] ?? "")); ?>">
            <h3><?php echo h((string)($app["nome"] ?? "")); ?></h3>
          </a>

          <div class="meta"><?php echo (int)($app["downloads"] ?? 0); ?> downloads</div>

          <div style="margin-top:10px;">
            <a class="clean" href="app.php?id=<?php echo rawurlencode((string)($app["id"] ?? "")); ?>">
              <button class="btn btn-install" type="button">Instalar</button>
            </a>
          </div>
        </div>
      </div>
    <?php endforeach; ?>
  </div>
</div>
</body>
</html>
