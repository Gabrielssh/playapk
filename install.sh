#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Gabrielssh/playapk.git}"
APP_DIR="${APP_DIR:-/var/www/playapk}"
PORT="${PORT:-8181}"

# Defina na instalação: sudo ADMIN_PASS="SuaSenha" bash install.sh
ADMIN_PASS="${ADMIN_PASS:-Cle1202}"

# 1 = abre UFW
OPEN_UFW="${OPEN_UFW:-1}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Use: sudo bash install.sh"
  exit 1
fi

echo "==> Instalando pacotes..."
apt update -y
apt install -y apache2 git curl \
  php libapache2-mod-php php-cli php-json php-mbstring

echo "==> Habilitando módulos Apache..."
a2enmod rewrite headers >/dev/null || true

echo "==> Apache escutando na porta ${PORT}..."
if ! grep -qE "^[[:space:]]*Listen[[:space:]]+${PORT}\b" /etc/apache2/ports.conf; then
  echo "" >> /etc/apache2/ports.conf
  echo "Listen ${PORT}" >> /etc/apache2/ports.conf
fi

echo "==> Clonando/atualizando repositório..."
mkdir -p "$APP_DIR"
if [ -d "$APP_DIR/.git" ]; then
  git -C "$APP_DIR" pull
else
  rm -rf "$APP_DIR"/*
  git clone "$REPO_URL" "$APP_DIR"
fi

echo "==> Criando pastas e apps.json..."
mkdir -p "$APP_DIR/apks" "$APP_DIR/img"
touch "$APP_DIR/apps.json"
if [ ! -s "$APP_DIR/apps.json" ]; then
  echo "[]" > "$APP_DIR/apps.json"
fi

echo "==> Permissões..."
chown -R root:root "$APP_DIR"
chown -R www-data:www-data "$APP_DIR/apks" "$APP_DIR/img" "$APP_DIR/apps.json"
find "$APP_DIR" -type d -exec chmod 755 {} \;
find "$APP_DIR" -type f -exec chmod 644 {} \;
chmod 664 "$APP_DIR/apps.json"

echo "==> Configurando PHP para upload 1GB (Apache)..."
PHPV="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
INI="/etc/php/${PHPV}/apache2/php.ini"

if [ ! -f "$INI" ]; then
  echo "ERRO: não encontrei php.ini em $INI"
  exit 1
fi

set_ini() {
  local key="$1" val="$2"
  if grep -qE "^[;[:space:]]*${key}[[:space:]]*=" "$INI"; then
    sed -i "s/^[;[:space:]]*${key}[[:space:]]*=.*/${key} = ${val}/" "$INI"
  else
    echo "${key} = ${val}" >> "$INI"
  fi
}

set_ini upload_max_filesize 1024M
set_ini post_max_size 1050M
set_ini max_execution_time 1800
set_ini max_input_time 1800
set_ini memory_limit 512M

echo "==> Configurando senha admin (hash) no admin.php..."
if [ -f "$APP_DIR/admin.php" ]; then
  HASH="$(php -r 'echo password_hash(getenv("ADMIN_PASS"), PASSWORD_DEFAULT);' ADMIN_PASS="$ADMIN_PASS")"
  # substitui placeholder
  sed -i "s|__ADMIN_HASH__|${HASH}|g" "$APP_DIR/admin.php" || true
else
  echo "AVISO: admin.php não encontrado em $APP_DIR (verifique seu repositório)."
fi

echo "==> Criando VirtualHost..."
cat > /etc/apache2/sites-available/playapk.conf <<EOF
<VirtualHost *:${PORT}>
  DocumentRoot ${APP_DIR}
  DirectoryIndex index.php index.html

  <Directory ${APP_DIR}>
    Options FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  # Segurança: não executar PHP em uploads
  <Directory ${APP_DIR}/apks>
    php_admin_flag engine off
    RemoveHandler .php .phtml .php3 .php4 .php5 .php7 .php8
    RemoveType .php .phtml .php3 .php4 .php5 .php7 .php8
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

a2ensite playapk.conf >/dev/null || true

echo "==> Reiniciando Apache..."
systemctl restart apache2

echo "==> Liberando firewall (opcional)..."
if [ "$OPEN_UFW" = "1" ]; then
  apt install -y ufw >/dev/null 2>&1 || true
  ufw allow "${PORT}/tcp" >/dev/null 2>&1 || true
fi

IP="$(curl -4 -s ifconfig.me || true)"
echo ""
echo "==> OK!"
echo "Site:  http://${IP:-SEU_IP}:${PORT}/"
echo "Admin: http://${IP:-SEU_IP}:${PORT}/admin.php"
echo "Senha admin: ${ADMIN_PASS}"
echo ""
echo "Checar limites PHP:"
echo "  php -i | grep -E \"upload_max_filesize|post_max_size\""
