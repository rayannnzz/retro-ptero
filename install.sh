#!/bin/bash
# Pterodactyl Retro Theme - installer / uninstaller
# Pakai: sudo bash install.sh [install|uninstall]
set -e

# Ganti sesuai repo GitHub kamu
REPO="${RETRO_REPO:-rayannnzz/retro-ptero}"
BRANCH="${RETRO_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

PANEL="${PTERO_DIR:-/var/www/pterodactyl}"
THEME_DIR="$PANEL/public/themes/retro"
MARK="<!-- retro-theme -->"
LINK="$MARK<link rel=\"stylesheet\" href=\"/themes/retro/retro.css?v=$(date +%s)\">"

FILES=(
  "resources/views/templates/base/core.blade.php"
  "resources/views/templates/auth/core.blade.php"
  "resources/views/layouts/admin.blade.php"
)

[ -d "$PANEL" ] || { echo "Panel tidak ditemukan di $PANEL (set PTERO_DIR=...)"; exit 1; }

case "${1:-install}" in
  install)
    mkdir -p "$THEME_DIR"
    LOCAL="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/retro.css"
    if [ -f "$LOCAL" ]; then
      cp "$LOCAL" "$THEME_DIR/retro.css"
    else
      curl -fsSL "$RAW/retro.css" -o "$THEME_DIR/retro.css" || { echo "Gagal download retro.css dari $RAW"; exit 1; }
    fi
    for f in "${FILES[@]}"; do
      p="$PANEL/$f"
      [ -f "$p" ] || { echo "skip (tidak ada): $f"; continue; }
      [ -f "$p.retro.bak" ] || cp "$p" "$p.retro.bak"
      if grep -q "retro-theme" "$p"; then
        sed -i "s|$MARK<link[^>]*>||" "$p"
      fi
      sed -i "s|</head>|$LINK</head>|" "$p"
      echo "patched: $f"
    done
    ;;
  uninstall)
    for f in "${FILES[@]}"; do
      p="$PANEL/$f"
      [ -f "$p.retro.bak" ] && mv "$p.retro.bak" "$p" && echo "restored: $f"
    done
    rm -rf "$THEME_DIR"
    ;;
  *) echo "Usage: $0 [install|uninstall]"; exit 1 ;;
esac

cd "$PANEL"
php artisan view:clear
php artisan config:clear
chown -R www-data:www-data "$PANEL" 2>/dev/null || chown -R nginx:nginx "$PANEL"
echo "Selesai. Hard refresh browser (Ctrl+Shift+R)."
