#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/Gabrielssh/playapk.git"
APP_DIR="/var/www/playapk"
SITE_CONF="/etc/apache2/sites-available/playapk.conf"
APACHE_PORT="8181"

REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"
DOMAIN="${DOMAIN:-}"   # opcional
OPEN_UFW="${OPEN_UFW:-1}" # 1 abre firewall

if [ "$(id -u)" -ne 0 ]; then
  echo "Use: sudo bash install.sh"
  exit 1
fi

echo "==> Ubuntu 22: instalando dependências..."
apt update -y
apt install -y apache2 git curl unzip \
  php libapache2-mod-php php-json php-mbstring php-xml php-curl

echo "==> Ativando módulos Apache..."
a2enmod rewrite headers >/dev/null || true

echo "==> Configurando Apache para escutar na porta $APACHE_PORT..."
# Garante que Apache escuta 8181
if ! grep -qE "^[[:space:]]*Listen[[:space:]]+$APACHE_PORT" /etc/apache2/ports.conf; then
  echo "Listen $APACHE_PORT" >> /etc/apache2/ports.conf
fi

echo "==> Baixando/atualizando projeto..."
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
chown -R www-data:www-data "$APP_DIR/apks" "$APP_DIR/img" "$APP_DIR/apps.json"
chmod -R 755 "$APP_DIR/apks" "$APP_DIR/img"
chmod 664 "$APP_DIR/apps.json"

echo "==> Criando VirtualHost na porta $APACHE_PORT..."
SERVER_NAME_LINE=""
if [ -n "$DOMAIN" ]; then
  SERVER_NAME_LINE="ServerName $DOMAIN"
fi

cat > "$SITE_CONF" <<EOF
<VirtualHost *:${APACHE_PORT}>
    $SERVER_NAME_LINE
    DocumentRoot $APP_DIR

    <Directory $APP_DIR>
        AllowOverride All
        Options FollowSymLinks
        Require all granted
    </Directory>

    # Segurança: impedir execução de PHP em /apks e /img
    <Directory $APP_DIR/apks>
        php_admin_flag engine off
        RemoveHandler .php .phtml .php3 .php4 .php5 .php7 .php8
        RemoveType .php .phtml .php3 .php4 .php5 .php7 .php8
        AddType application/vnd.android.package-archive .apk
        Header set X-Content-Type-Options "nosniff"
        Require all granted
    </Directory>

    <Directory $APP_DIR/img>
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

# Habilita o site e recarrega
a2ensite playapk.conf >/dev/null
systemctl reload apache2

echo "==> (Opcional) liberando firewall UFW..."
if [ "$OPEN_UFW" = "1" ]; then
  apt install -y ufw >/dev/null 2>&1 || true
  ufw allow "${APACHE_PORT}/tcp" >/dev/null 2>&1 || true
fi

IP="$(curl -4 -s ifconfig.me || true)"

echo ""
echo "==> OK! Instalado."
echo "Abra no navegador:"
if [ -n "$DOMAIN" ]; then
  echo "  http://$DOMAIN:$APACHE_PORT/"
else
  echo "  http://${IP:-SEU_IP}:$APACHE_PORT/"
fi
echo ""
echo "Admin:"
echo "  http://${DOMAIN:-${IP:-SEU_IP}}:$APACHE_PORT/admin.php"
echo ""
echo "IMPORTANTE: coloque ADMIN_PASS_HASH em admin.php (e onde tiver)."
echo "Gerar hash:"
echo "  php -r \"echo password_hash('SUA_SENHA', PASSWORD_DEFAULT), PHP_EOL;\""