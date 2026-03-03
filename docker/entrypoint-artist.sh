#!/bin/bash
set -e

# =============================================================================
# Mautic for Artists — Custom Entrypoint
# 1. Brands artist themes with color and logo
# 2. Runs mautic:install if not yet installed
# 3. Delegates to official Mautic entrypoint (runs migrations + starts Apache)
# 4. Seeds Mautic with artist content (segments, templates, campaigns)
# =============================================================================

BRAND_COLOR="${ARTIST_BRAND_COLOR:-#6C63FF}"
LOGO_URL="${ARTIST_LOGO_URL:-/themes/artist-welcome/images/placeholder-logo.png}"
SEED_MARKER="/var/www/html/var/.artist-seeded"
INSTALL_MARKER="/var/www/html/var/.artist-installed"

MAUTIC_ADMIN_EMAIL="${MAUTIC_ADMIN_EMAIL:-admin@example.com}"
MAUTIC_ADMIN_PASSWORD="${MAUTIC_ADMIN_PASSWORD:-changeme}"
MAUTIC_URL="${MAUTIC_URL:-http://localhost:8080}"

# Map our env vars to what the official Mautic image expects
export MAUTIC_DB_DATABASE="${MAUTIC_DB_NAME:-mautic}"
export MAUTIC_DB_HOST="${MAUTIC_DB_HOST:-db}"
export MAUTIC_DB_PORT="${MAUTIC_DB_PORT:-3306}"
export MAUTIC_DB_USER="${MAUTIC_DB_USER:-mautic}"
export MAUTIC_DB_PASSWORD="${MAUTIC_DB_PASSWORD}"

# --- Step 1: Brand artist themes ---
echo "[artist-entrypoint] Branding themes with color=${BRAND_COLOR}"

for theme_dir in /var/www/html/docroot/themes/artist-*/; do
    if [ -d "$theme_dir" ]; then
        find "$theme_dir" -name "*.twig" -exec \
            sed -i "s|{{BRAND_COLOR}}|${BRAND_COLOR}|g; s|{{LOGO_URL}}|${LOGO_URL}|g" {} \;
    fi
done

# Also brand CSS files
for theme_dir in /var/www/html/docroot/themes/artist-*/; do
    if [ -d "${theme_dir}css" ]; then
        find "${theme_dir}css" -name "*.css" -exec \
            sed -i "s|{{BRAND_COLOR}}|${BRAND_COLOR}|g" {} \;
    fi
done

echo "[artist-entrypoint] Theme branding complete"

# --- Step 2: Install Mautic if not yet installed ---
# The official entrypoint checks local.php for site_url to decide if installed.
# We run mautic:install to set up the database and create the admin user.
if [ ! -f "$INSTALL_MARKER" ]; then
    echo "[artist-entrypoint] First run detected — installing Mautic..."

    # Wait for the official entrypoint scripts to set up local.php and check DB
    # We source the official startup scripts first
    export DOCKER_MAUTIC_ROLE="${DOCKER_MAUTIC_ROLE:-mautic_web}"
    export MAUTIC_VOLUME_CONFIG="${MAUTIC_VOLUME_CONFIG:-/var/www/html/config}"
    export MAUTIC_VOLUME_LOGS="${MAUTIC_VOLUME_LOGS:-/var/www/html/var/logs}"
    export MAUTIC_VOLUME_MEDIA="${MAUTIC_VOLUME_MEDIA:-/var/www/html/docroot/media}"
    export MAUTIC_VOLUME_FILES="${MAUTIC_VOLUME_FILES:-/var/www/html/docroot/media/files}"
    export MAUTIC_VOLUME_IMAGES="${MAUTIC_VOLUME_IMAGES:-/var/www/html/docroot/media/images}"
    export MAUTIC_VAR="${MAUTIC_VAR:-/var/www/html/var}"
    export MAUTIC_CONSOLE="${MAUTIC_CONSOLE:-/var/www/html/bin/console}"
    export MAUTIC_WWW_USER="${MAUTIC_WWW_USER:-www-data}"
    export MAUTIC_WWW_GROUP="${MAUTIC_WWW_GROUP:-www-data}"
    export MAUTIC_DB_PORT="${MAUTIC_DB_PORT:-3306}"
    export MAUTIC_VOLUMES="${MAUTIC_VOLUME_CONFIG} ${MAUTIC_VAR} ${MAUTIC_VOLUME_LOGS} ${MAUTIC_VOLUME_MEDIA} ${MAUTIC_VOLUME_FILES} ${MAUTIC_VOLUME_IMAGES}"

    # Run official pre-checks
    /startup/check_volumes_exist_ownership.sh
    /startup/check_environment_variables.sh
    /startup/check_database_connection.sh
    /startup/check_local_php_exists.sh

    # Fix log directory permissions
    mkdir -p /var/www/html/var/logs
    chown -R www-data:www-data /var/www/html/var

    # Run Mautic install
    echo "[artist-entrypoint] Running mautic:install..."
    su -s /bin/bash www-data -c "php /var/www/html/bin/console mautic:install --force \
        --db_host '${MAUTIC_DB_HOST}' \
        --db_port '${MAUTIC_DB_PORT}' \
        --db_name '${MAUTIC_DB_DATABASE}' \
        --db_user '${MAUTIC_DB_USER}' \
        --db_password '${MAUTIC_DB_PASSWORD}' \
        --admin_email '${MAUTIC_ADMIN_EMAIL}' \
        --admin_password '${MAUTIC_ADMIN_PASSWORD}' \
        '${MAUTIC_URL}'"

    echo "[artist-entrypoint] Running database migrations..."
    su -s /bin/bash www-data -c "php /var/www/html/bin/console doctrine:migrations:migrate -n" || true

    # Enable API with Basic Auth + set mailer DSN by editing local.php directly
    echo "[artist-entrypoint] Enabling API with Basic Auth..."
    LOCAL_PHP="/var/www/html/config/local.php"
    if [ -f "$LOCAL_PHP" ]; then
        # Add api_enabled, api_enable_basic_auth before the closing );
        sed -i "s|);|\t'api_enabled' => true,\n\t'api_enable_basic_auth' => true,\n);|" "$LOCAL_PHP"

        # Set mailer DSN if provided
        if [ "${MAUTIC_MAILER_DSN}" != "null://null" ] && [ -n "${MAUTIC_MAILER_DSN}" ]; then
            echo "[artist-entrypoint] Configuring mailer DSN..."
            sed -i "s|'mailer_dsn' => '[^']*'|'mailer_dsn' => '${MAUTIC_MAILER_DSN}'|" "$LOCAL_PHP"
        fi
    fi

    # Clear cache
    su -s /bin/bash www-data -c "php /var/www/html/bin/console cache:clear" 2>/dev/null || true

    touch "$INSTALL_MARKER"
    echo "[artist-entrypoint] Mautic installation complete!"
fi

# --- Step 3: Run seed script in background after Apache starts ---
if [ ! -f "$SEED_MARKER" ]; then
    (
        echo "[artist-entrypoint] Waiting for Apache to start before seeding..."
        sleep 10

        ATTEMPTS=0
        MAX_ATTEMPTS=60
        while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80/api/contacts?limit=1 -u "${MAUTIC_ADMIN_USERNAME:-admin}:${MAUTIC_ADMIN_PASSWORD}" 2>/dev/null || echo "000")
            if [ "$HTTP_CODE" = "200" ]; then
                echo "[artist-entrypoint] API is responding, starting seed..."
                /seed-mautic.sh && touch "$SEED_MARKER"
                break
            fi
            ATTEMPTS=$((ATTEMPTS + 1))
            sleep 5
        done
        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            echo "[artist-entrypoint] WARNING: Timed out waiting for API. Seeding skipped."
            echo "[artist-entrypoint] You can run 'docker exec <container> /seed-mautic.sh' manually."
        fi
    ) &
fi

# --- Step 4: Start Apache (skip official entrypoint since we already ran its steps) ---
echo "[artist-entrypoint] Starting Apache..."
exec apache2-foreground
