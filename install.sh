#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
APP_DIR="${APP_DIR:-/var/www/playapk}"
REPO_URL="${REPO_URL:-https://github.com/Gabrielssh/playapk.git}"
PORT="${PORT:-8181}"
OPEN_UFW="${OPEN_UFW:-1}"

# Opcional: definir senha admin e gravar hash automaticamente no admin.php
# Ex: sudo ADMIN_PASS="Cle1202" bash install.sh
ADMIN_PASS="${ADMIN_PASS:-}"
# ==================

if [ "$(id -u)" -ne 0 ]; then
  echo "Rode como root: sudo bash install.sh"
  exit 1
fi

echo "==> Instalando dependências (Ubuntu 22)..."
apt update -y
apt install -y apache2 git curl unzip \
  php libapache2-mod-php php-cli php-json php-mbstring php-xml php-curl

echo "==> Habilitando módulos Apache..."
a2enmod rewrite headers >/dev/null || true

echo "==> Configurando Apache para escutar na porta ${PORT}..."
# garantir Listen PORT em ports.conf
if ! grep -qE "^[[:space:]]*Listen[[:space:]]+${PORT}\b" /etc/apache2/ports.conf; then
  echo "" >> /etc/apache2/ports.conf
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

echo "==> Baixando/atualizando site do GitHub..."
mkdir -p "$APP_DIR"

if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" pull
else
  rm -rf "$APP_DIR"/*
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "==> Criando pastas e arquivo apps.json..."
mkdir -p "$APP_DIR/apks" "$APP_DIR/img"
touch "$APP_DIR/apps.json"
if [ ! -s "$APP_DIR/apps.json" ]; then
  echo "[]" > "$APP_DIR/apps.json"
fi

echo "==> Permissões corretas..."
# Dono do projeto pode ser root, mas pastas de upload precisam ser graváveis pelo Apache
chown -R root:root "$APP_DIR"
chown -R www-data:www-data "$APP_DIR/apks" "$APP_DIR/img" "$APP_DIR/apps.json"

# Permissões de leitura do site
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;
chmod 664 "$APP_DIR/apps.json"

echo "==> Criando VirtualHost na porta ${PORT}..."
cat > /etc/apache2/sites-available/playapk.conf <<EOF
<VirtualHost *:${PORT}>
    ServerName 151.244.242.225
    DocumentRoot ${APP_DIR}

    DirectoryIndex index.php index.html

    <Directory ${APP_DIR}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Segurança: não executar PHP dentro de /apks e /img
    <Directory ${APP_DIR}/apks>
        php_admin_flag engine off
        RemoveHandler .php .phtml .php3 .php4 .php5 .php7 .php8
        RemoveType .php .phtml .php3 .php4 .php5 .php7 .php8
        AddType application/vnd.android.package-archive .apk
        Header set X-Content-Type-Options "nosniff"
        Require all granted
    </Directory>

    <Directory ${APP_DIR}/img>
        php_admin_flag engine off
        RemoveHandler .php .phtml .php3 .php4 .php5 .php7 .php8
        RemoveType .php .phtml .php3 .php4 .php5 .php7 .php8
        Header set X-Content-Type-Options "nosniff"
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/playapk_error.log
    CustomLog \${APACHE_LOG_DIR}/playapk_access.log combined
</VirtualHost>
EOF

echo "==> Habilitando site e reiniciando Apache..."
a2ensite playapk.conf >/dev/null
# Não desabilito o 000-default porque geralmente está no :80; não atrapalha a 8181
systemctl restart apache2

echo "==> Liberando firewall (UFW) na porta ${PORT}..."
if [ "$OPEN_UFW" = "1" ]; then
  apt install -y ufw >/dev/null 2>&1 || true
  ufw allow "${PORT}/tcp" >/dev/null 2>&1 || true
fi

# ===== Opcional: gravar senha admin automaticamente =====
if [ -n "$ADMIN_PASS" ]; then
  echo "==> Configurando senha admin automaticamente..."
  HASH="$(php -r "echo password_hash('${ADMIN_PASS}', PASSWORD_DEFAULT);")"

  # Substitui a constante no admin.php (se existir)
  if [ -f "${APP_DIR}/admin.php" ]; then
    sed -i "s|const ADMIN_PASS_HASH = '.*';|const ADMIN_PASS_HASH = '${HASH}';|g" "${APP_DIR}/admin.php" || true
  fi

  # Se você tiver ADMIN_PASS_HASH em outros arquivos, pode adicionar aqui também.
  systemctl reload apache2
fi

IP="$(curl -4 -s ifconfig.me || true)"

echo ""
echo "==> PRONTO!"
echo "Site:   http://${IP:-151.244.242.225}:${PORT}/"
echo "Admin:  http://${IP:-151.244.242.225}:${PORT}/admin.php"
if [ -n "$ADMIN_PASS" ]; then
  echo "Senha admin definida: ${ADMIN_PASS}"
else
  echo "Senha admin: você precisa colocar o ADMIN_PASS_HASH no admin.php"
fi
echo ""
echo "Se ainda der Forbidden, rode:"
echo "  sudo tail -n 80 /var/log/apache2/playapk_error.log"
echo "  sudo apache2ctl -S"
