#!/bin/bash
set -e

# =============================================================================
# Mautic for Artists — Custom Entrypoint
# 1. Brands artist themes with color and logo
# 2. Delegates to official Mautic entrypoint
# 3. Seeds Mautic with artist content (segments, templates, campaigns)
# =============================================================================

BRAND_COLOR="${ARTIST_BRAND_COLOR:-#6C63FF}"
LOGO_URL="${ARTIST_LOGO_URL:-/media/images/placeholder-logo.png}"
SEED_MARKER="/var/www/html/var/.artist-seeded"

# --- Step 1: Brand artist themes ---
echo "[artist-entrypoint] Branding themes with color=${BRAND_COLOR}"

for theme_dir in /var/www/html/themes/artist-*/; do
    if [ -d "$theme_dir" ]; then
        find "$theme_dir" -name "*.twig" -exec \
            sed -i "s|{{BRAND_COLOR}}|${BRAND_COLOR}|g; s|{{LOGO_URL}}|${LOGO_URL}|g" {} \;
    fi
done

# Also brand CSS files
for theme_dir in /var/www/html/themes/artist-*/; do
    if [ -d "${theme_dir}css" ]; then
        find "${theme_dir}css" -name "*.css" -exec \
            sed -i "s|{{BRAND_COLOR}}|${BRAND_COLOR}|g" {} \;
    fi
done

echo "[artist-entrypoint] Theme branding complete"

# --- Step 2: Delegate to official Mautic entrypoint ---
# The official entrypoint handles mautic:install on first run,
# config generation, and permission setup.
echo "[artist-entrypoint] Delegating to official Mautic entrypoint..."

# Run the seed script in the background after Mautic is ready
if [ ! -f "$SEED_MARKER" ]; then
    (
        echo "[artist-entrypoint] Waiting for Mautic to be ready before seeding..."
        # Wait for Mautic to be fully installed and responsive
        ATTEMPTS=0
        MAX_ATTEMPTS=90
        while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:80/s/login 2>/dev/null | grep -q "200\|302"; then
                echo "[artist-entrypoint] Mautic is ready, starting seed..."
                sleep 5  # Give it a moment to fully stabilize
                /seed-mautic.sh && touch "$SEED_MARKER"
                break
            fi
            ATTEMPTS=$((ATTEMPTS + 1))
            sleep 10
        done
        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            echo "[artist-entrypoint] WARNING: Timed out waiting for Mautic. Seeding skipped."
            echo "[artist-entrypoint] You can run 'docker exec <container> /seed-mautic.sh' manually."
        fi
    ) &
fi

# Execute the official Mautic entrypoint with the original command
exec /entrypoint.sh "$@"
