sudo bash -lc '
set -euo pipefail

WORK=/root/playapk_repo
ZIP=/root/playapk.zip

rm -rf "$WORK" "$ZIP"
mkdir -p "$WORK"

# ---------------- index.php ----------------
cat > "$WORK/index.php" <<'"'"'PHP'"'"'
<?php
declare(strict_types=1);

const APPS_FILE = __DIR__ . "/apps.json";
function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, "UTF-8"); }

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
PHP

# ---------------- app.php ----------------
cat > "$WORK/app.php" <<'"'"'PHP'"'"'
<?php
declare(strict_types=1);

const APPS_FILE = __DIR__ . "/apps.json";
function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, "UTF-8"); }

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
.btn{border:0;cursor:pointer;border-radius:14px;padding:12px 14px;font-weight:900;font-size:14px;background:var(--green);color:#fff;width:100%;}
.note{margin-top:10px;color:var(--muted);font-size:12px;line-height:1.35}
a.clean{text-decoration:none;}
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
      <a class="clean" href="download.php?id=<?php echo rawurlencode((string)($appFound["id"] ?? "")); ?>">
        <button class="btn" type="button">Instalar</button>
      </a>
      <div class="note">O Android vai pedir confirmação para instalar.</div>
    </div>
  </div>
</div>
</body>
</html>
PHP

# ---------------- download.php ----------------
cat > "$WORK/download.php" <<'"'"'PHP'"'"'
<?php
declare(strict_types=1);

const APPS_FILE = __DIR__ . "/apps.json";
const APK_DIR   = __DIR__ . "/apks";

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
PHP

# ---------------- admin.php (corrigido confirm) ----------------
cat > "$WORK/admin.php" <<'"'"'PHP'"'"'
<?php
declare(strict_types=1);
session_start();

const ADMIN_PASS_HASH = '__ADMIN_HASH__';

const APPS_FILE = __DIR__ . '/apps.json';
const APK_DIR   = __DIR__ . '/apks';
const IMG_DIR   = __DIR__ . '/img';

function h(string $s): string { return htmlspecialchars($s, ENT_QUOTES, 'UTF-8'); }

function load_apps(): array {
    if (!file_exists(APPS_FILE)) return [];
    $data = json_decode(file_get_contents(APPS_FILE) ?: "[]", true);
    return is_array($data) ? $data : [];
}
function save_apps(array $apps): void {
    file_put_contents(APPS_FILE, json_encode(array_values($apps), JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT), LOCK_EX);
}
function upload_err_text(int $code): string {
    return match ($code) {
        UPLOAD_ERR_OK => "OK",
        UPLOAD_ERR_INI_SIZE => "Arquivo excede upload_max_filesize do PHP",
        UPLOAD_ERR_FORM_SIZE => "Arquivo excede MAX_FILE_SIZE do formulário",
        UPLOAD_ERR_PARTIAL => "Upload parcial (conexão caiu)",
        UPLOAD_ERR_NO_FILE => "Nenhum arquivo enviado",
        UPLOAD_ERR_NO_TMP_DIR => "Sem pasta temporária no servidor",
        UPLOAD_ERR_CANT_WRITE => "Falha ao gravar no disco",
        UPLOAD_ERR_EXTENSION => "Upload bloqueado por extensão do PHP",
        default => "Erro desconhecido",
    };
}

$apps = load_apps();
$isAdmin = !empty($_SESSION["admin"]);
$flash = "";

if (isset($_POST["login"])) {
    $senha = (string)($_POST["senha"] ?? "");
    if (password_verify($senha, ADMIN_PASS_HASH)) {
        $_SESSION["admin"] = true;
        session_regenerate_id(true);
        header("Location: admin.php"); exit;
    }
    $flash = "Senha incorreta.";
}

if (isset($_GET["logout"])) {
    $_SESSION = [];
    session_destroy();
    header("Location: admin.php"); exit;
}

if (isset($_POST["upload"]) && $isAdmin) {
    $nome = trim((string)($_POST["nome"] ?? ""));

    if ($nome === "") {
        $flash = "Informe o nome do app.";
    } elseif (empty($_FILES["apk"]) || empty($_FILES["img"])) {
        $flash = "Envie o APK e a imagem.";
    } else {
        $apkErr = (int)($_FILES["apk"]["error"] ?? UPLOAD_ERR_NO_FILE);
        $imgErr = (int)($_FILES["img"]["error"] ?? UPLOAD_ERR_NO_FILE);

        if ($apkErr !== UPLOAD_ERR_OK) {
            $flash = "Erro no APK: " . upload_err_text($apkErr);
        } elseif ($imgErr !== UPLOAD_ERR_OK) {
            $flash = "Erro na imagem: " . upload_err_text($imgErr);
        } else {
            $apkTmp = (string)($_FILES["apk"]["tmp_name"] ?? "");
            $imgTmp = (string)($_FILES["img"]["tmp_name"] ?? "");

            if (!is_uploaded_file($apkTmp) || !is_uploaded_file($imgTmp)) {
                $flash = "Falha: arquivo não chegou corretamente (tmp).";
            } else {
                $apkExt = strtolower(pathinfo($_FILES["apk"]["name"] ?? "", PATHINFO_EXTENSION));
                if ($apkExt !== "apk") {
                    $flash = "O arquivo precisa ser .apk";
                } else {
                    $imgInfo = @getimagesize($imgTmp);
                    if (!$imgInfo) {
                        $flash = "Imagem inválida.";
                    } else {
                        $mime = $imgInfo["mime"] ?? "";
                        $allowed = ["image/jpeg"=>"jpg","image/png"=>"png","image/webp"=>"webp"];
                        if (!isset($allowed[$mime])) {
                            $flash = "Formato de imagem não permitido (use jpg/png/webp).";
                        } else {
                            $id = bin2hex(random_bytes(8));
                            $apkName = $id . ".apk";
                            $imgName = $id . "." . $allowed[$mime];

                            if (!move_uploaded_file($apkTmp, APK_DIR . "/" . $apkName)) {
                                $flash = "Falha ao salvar o APK (permissão/pasta).";
                            } elseif (!move_uploaded_file($imgTmp, IMG_DIR . "/" . $imgName)) {
                                @unlink(APK_DIR . "/" . $apkName);
                                $flash = "Falha ao salvar a imagem (permissão/pasta).";
                            } else {
                                $apps[] = ["id"=>$id,"nome"=>$nome,"apk"=>$apkName,"img"=>$imgName,"downloads"=>0];
                                save_apps($apps);
                                header("Location: admin.php"); exit;
                            }
                        }
                    }
                }
            }
        }
    }
}

if (isset($_GET["delete"]) && $isAdmin) {
    $id = (string)($_GET["delete"] ?? "");
    foreach ($apps as $k => $app) {
        if (($app["id"] ?? "") === $id) {
            @unlink(APK_DIR . "/" . ($app["apk"] ?? ""));
            @unlink(IMG_DIR . "/" . ($app["img"] ?? ""));
            unset($apps[$k]);
            save_apps($apps);
            break;
        }
    }
    header("Location: admin.php"); exit;
}

$limits = [
  "upload_max_filesize" => ini_get("upload_max_filesize"),
  "post_max_size"       => ini_get("post_max_size"),
  "max_execution_time"  => ini_get("max_execution_time"),
  "max_input_time"      => ini_get("max_input_time"),
];
?>
<!doctype html>
<html lang="pt-br">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Admin - Play Apk</title>
<style>
:root{--green:#00c853;--bg:#f4f6f8;--text:#111;--muted:#5f6368;--border:#e6e8eb;}
*{box-sizing:border-box}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;background:var(--bg);color:var(--text);}
.topbar{background:var(--green);color:#fff;padding:12px 14px;display:flex;align-items:center;justify-content:space-between;}
.topbar a{color:#fff;text-decoration:none;font-weight:900}
.container{max-width:900px;margin:0 auto;padding:14px;}
.box{background:#fff;border:1px solid var(--border);border-radius:18px;padding:14px;margin-top:12px;}
input{width:100%;padding:10px 12px;border-radius:12px;border:1px solid var(--border);margin-top:8px;}
button{border:0;cursor:pointer;border-radius:12px;padding:10px 12px;font-weight:900;background:var(--green);color:#fff;width:100%;margin-top:10px;}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:10px;margin-top:12px;}
.card{background:#fff;border:1px solid var(--border);border-radius:18px;padding:12px;}
.small{color:var(--muted);font-size:12px;}
.del{background:#e53935;}
.flash{background:#111;color:#fff;padding:10px 12px;border-radius:12px;margin-top:12px;}
</style>
</head>
<body>
<div class="topbar">
  <div style="font-weight:900;">Admin - Play Apk</div>
  <div><a href="index.php">Ver site</a><?php if ($isAdmin): ?> | <a href="?logout">Sair</a><?php endif; ?></div>
</div>

<div class="container">
<?php if ($flash !== ""): ?>
  <div class="flash"><?php echo h($flash); ?></div>
<?php endif; ?>

<div class="box">
  <div style="font-weight:900;">Limites atuais do PHP</div>
  <div class="small">
    upload_max_filesize: <?php echo h((string)$limits["upload_max_filesize"]); ?> |
    post_max_size: <?php echo h((string)$limits["post_max_size"]); ?> |
    max_execution_time: <?php echo h((string)$limits["max_execution_time"]); ?> |
    max_input_time: <?php echo h((string)$limits["max_input_time"]); ?>
  </div>
</div>

<?php if (!$isAdmin): ?>
  <div class="box">
    <div style="font-weight:900;">Login</div>
    <form method="POST">
      <input type="password" name="senha" placeholder="Senha" required>
      <button name="login" value="1">Entrar</button>
    </form>
  </div>
<?php else: ?>
  <div class="box">
    <div style="font-weight:900;">Enviar App</div>
    <form method="POST" enctype="multipart/form-data">
      <input type="text" name="nome" placeholder="Nome do app" required>
      <input type="file" name="apk" accept=".apk" required>
      <input type="file" name="img" accept="image/*" required>
      <button name="upload" value="1">Enviar</button>
    </form>
  </div>

  <div class="grid">
    <?php foreach ($apps as $app): ?>
      <div class="card">
        <div style="font-weight:900;"><?php echo h((string)($app["nome"] ?? "")); ?></div>
        <div class="small"><?php echo (int)($app["downloads"] ?? 0); ?> downloads</div>
        <form method="GET" onsubmit="return confirm(\'Excluir este app?\');">
          <input type="hidden" name="delete" value="<?php echo h((string)($app["id"] ?? "")); ?>">
          <button class="del" type="submit">Excluir</button>
        </form>
      </div>
    <?php endforeach; ?>
  </div>
<?php endif; ?>

</div>
</body>
</html>
PHP

# data + htaccess
echo "[]" > "$WORK/apps.json"
cat > "$WORK/.htaccess" <<'"'"'HT'"'"'
Options -Indexes
HT

# ---------------- install.sh (curto e estável) ----------------
cat > "$WORK/install.sh" <<'"'"'SH'"'"'
#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Gabrielssh/playapk.git}"
APP_DIR="${APP_DIR:-/var/www/playapk}"
PORT="${PORT:-8181}"
ADMIN_PASS="${ADMIN_PASS:-Cle1202}"
OPEN_UFW="${OPEN_UFW:-1}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Use: sudo bash install.sh"
  exit 1
fi

apt update -y
apt install -y apache2 git curl \
  php libapache2-mod-php php-cli php-json php-mbstring

a2enmod rewrite headers >/dev/null || true

if ! grep -qE "^[[:space:]]*Listen[[:space:]]+${PORT}\b" /etc/apache2/ports.conf; then
  echo "" >> /etc/apache2/ports.conf
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" pull
else
  rm -rf "$APP_DIR"/*
  git clone "$REPO_URL" "$APP_DIR"
fi

mkdir -p "$APP_DIR/apks" "$APP_DIR/img"
touch "$APP_DIR/apps.json"
[ -s "$APP_DIR/apps.json" ] || echo "[]" > "$APP_DIR/apps.json"

chown -R root:root "$APP_DIR"
chown -R www-data:www-data "$APP_DIR/apks" "$APP_DIR/img" "$APP_DIR/apps.json"
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;
chmod 664 "$APP_DIR/apps.json"

PHPV="$(php -r "echo PHP_MAJOR_VERSION.\".\".PHP_MINOR_VERSION;")"
INI="/etc/php/${PHPV}/apache2/php.ini"
if [ -f "$INI" ]; then
  sed -i "s/^[;[:space:]]*upload_max_filesize[[:space:]]*=.*/upload_max_filesize = 1024M/" "$INI" || true
  sed -i "s/^[;[:space:]]*post_max_size[[:space:]]*=.*/post_max_size = 1050M/" "$INI" || true
  sed -i "s/^[;[:space:]]*max_execution_time[[:space:]]*=.*/max_execution_time = 1800/" "$INI" || true
  sed -i "s/^[;[:space:]]*max_input_time[[:space:]]*=.*/max_input_time = 1800/" "$INI" || true
  sed -i "s/^[;[:space:]]*memory_limit[[:space:]]*=.*/memory_limit = 512M/" "$INI" || true
fi

if [ -f "$APP_DIR/admin.php" ]; then
  HASH="$(php -r "echo password_hash(getenv(\"ADMIN_PASS\"), PASSWORD_DEFAULT);" ADMIN_PASS="$ADMIN_PASS")"
  sed -i "s|__ADMIN_HASH__|${HASH}|g" "$APP_DIR/admin.php" || true
fi

cat > /etc/apache2/sites-available/playapk.conf <<EOF
<VirtualHost *:${PORT}>
  DocumentRoot ${APP_DIR}
  DirectoryIndex index.php index.html

  <Directory ${APP_DIR}>
    Options FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF

a2ensite playapk.conf >/dev/null || true
systemctl restart apache2

if [ "$OPEN_UFW" = "1" ]; then
  apt install -y ufw >/dev/null 2>&1 || true
  ufw allow "${PORT}/tcp" >/dev/null 2>&1 || true
fi

IP="$(curl -4 -s ifconfig.me || true)"
echo "Site:  http://${IP:-SEU_IP}:${PORT}/"
echo "Admin: http://${IP:-SEU_IP}:${PORT}/admin.php"
echo "Senha admin: ${ADMIN_PASS}"
SH
chmod +x "$WORK/install.sh"

# README (fechado corretamente)
cat > "$WORK/README.md" <<'"'"'MD'"'"'
# PlayApk

## Instalar (Ubuntu 22 / Apache / porta 8181)
```bash
curl -fsSL https://raw.githubusercontent.com/Gabrielssh/playapk/main/install.sh | sudo ADMIN_PASS="Cle1202" bash
