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
    <div class="small">Entre com sua senha admin</div>
    <form method="POST">
      <input type="password" name="senha" placeholder="Senha" required>
      <button name="login" value="1">Entrar</button>
    </form>
  </div>
<?php else: ?>
  <div class="box">
    <div style="font-weight:900;">Enviar App</div>
    <div class="small">Envie .apk e uma imagem (jpg/png/webp)</div>
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
        <form method="GET" onsubmit="return confirm('Excluir este app?');">
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
