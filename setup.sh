#!/bin/bash
set -e

# =============================================================================
# Mautic for Artists — Interactive Setup Wizard
# =============================================================================

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║       Mautic for Artists — Setup         ║"
    echo "  ║   Email Marketing for Musicians          ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
prompt()  { echo -en "${BOLD}$1${NC}"; }

# Check prerequisites
check_prerequisites() {
    local missing=0

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        echo "  https://docs.docker.com/get-docker/"
        missing=1
    fi

    if ! docker compose version &> /dev/null 2>&1; then
        error "Docker Compose (v2) is not available."
        echo "  https://docs.docker.com/compose/install/"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        echo ""
        error "Please install the missing prerequisites and try again."
        exit 1
    fi

    info "Prerequisites check passed"
}

# Generate random password
generate_password() {
    openssl rand -base64 24 | tr -d '/+=' | head -c 32
}

# Validate hex color
validate_color() {
    if [[ "$1" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        return 0
    fi
    return 1
}

# Validate email
validate_email() {
    if [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

# =============================================================================
# Main Setup Flow
# =============================================================================

banner
check_prerequisites

echo -e "${BOLD}Let's set up your email marketing platform.${NC}"
echo -e "${DIM}Press Enter to accept the default value shown in [brackets].${NC}"
echo ""

# --- Artist Name ---
prompt "Artist / Band name [My Artist]: "
read -r ARTIST_NAME
ARTIST_NAME="${ARTIST_NAME:-My Artist}"

# --- Brand Color ---
while true; do
    prompt "Brand color (hex, e.g. #6C63FF) [#6C63FF]: "
    read -r ARTIST_BRAND_COLOR
    ARTIST_BRAND_COLOR="${ARTIST_BRAND_COLOR:-#6C63FF}"
    if validate_color "$ARTIST_BRAND_COLOR"; then
        break
    fi
    warn "Please enter a valid hex color (e.g. #FF5500)"
done

# --- Logo URL ---
prompt "Logo URL (or press Enter for placeholder) []: "
read -r ARTIST_LOGO_URL
ARTIST_LOGO_URL="${ARTIST_LOGO_URL:-/media/images/placeholder-logo.png}"

# --- Domain ---
prompt "Domain (where Mautic will be hosted) [localhost]: "
read -r ARTIST_DOMAIN
ARTIST_DOMAIN="${ARTIST_DOMAIN:-localhost}"

# --- Port ---
prompt "Port for Mautic web UI [8080]: "
read -r MAUTIC_PORT
MAUTIC_PORT="${MAUTIC_PORT:-8080}"

# --- Mautic URL ---
if [ "$ARTIST_DOMAIN" = "localhost" ]; then
    MAUTIC_URL="http://localhost:${MAUTIC_PORT}"
else
    MAUTIC_URL="https://${ARTIST_DOMAIN}"
fi

# --- Admin Email ---
while true; do
    prompt "Admin email address: "
    read -r MAUTIC_ADMIN_EMAIL
    if validate_email "$MAUTIC_ADMIN_EMAIL"; then
        break
    fi
    warn "Please enter a valid email address"
done

# --- Admin Password ---
while true; do
    prompt "Admin password (min 8 characters): "
    read -rs MAUTIC_ADMIN_PASSWORD
    echo ""
    if [ ${#MAUTIC_ADMIN_PASSWORD} -ge 8 ]; then
        break
    fi
    warn "Password must be at least 8 characters"
done

# --- Admin Username ---
prompt "Admin username [admin]: "
read -r MAUTIC_ADMIN_USERNAME
MAUTIC_ADMIN_USERNAME="${MAUTIC_ADMIN_USERNAME:-admin}"

# --- SMTP Provider ---
echo ""
echo -e "${BOLD}Email Provider Setup${NC}"
echo -e "${DIM}Choose your SMTP provider to send emails.${NC}"
echo ""
echo "  1) Mailgun"
echo "  2) Amazon SES"
echo "  3) SendGrid"
echo "  4) Brevo (Sendinblue)"
echo "  5) Other SMTP"
echo "  6) Skip (configure later in Mautic)"
echo ""
prompt "Select provider [6]: "
read -r SMTP_CHOICE
SMTP_CHOICE="${SMTP_CHOICE:-6}"

MAUTIC_MAILER_DSN="null://null"

case "$SMTP_CHOICE" in
    1)
        prompt "Mailgun SMTP username (postmaster@mg.yourdomain.com): "
        read -r SMTP_USER
        prompt "Mailgun SMTP password: "
        read -rs SMTP_PASS
        echo ""
        MAUTIC_MAILER_DSN="smtp://${SMTP_USER}:${SMTP_PASS}@smtp.mailgun.org:587"
        ;;
    2)
        prompt "SES SMTP username: "
        read -r SMTP_USER
        prompt "SES SMTP password: "
        read -rs SMTP_PASS
        echo ""
        prompt "SES region (e.g. us-east-1) [us-east-1]: "
        read -r SES_REGION
        SES_REGION="${SES_REGION:-us-east-1}"
        MAUTIC_MAILER_DSN="smtp://${SMTP_USER}:${SMTP_PASS}@email-smtp.${SES_REGION}.amazonaws.com:587"
        ;;
    3)
        prompt "SendGrid API key: "
        read -rs SMTP_PASS
        echo ""
        MAUTIC_MAILER_DSN="smtp://apikey:${SMTP_PASS}@smtp.sendgrid.net:587"
        ;;
    4)
        prompt "Brevo SMTP login (email): "
        read -r SMTP_USER
        prompt "Brevo SMTP key: "
        read -rs SMTP_PASS
        echo ""
        MAUTIC_MAILER_DSN="smtp://${SMTP_USER}:${SMTP_PASS}@smtp-relay.brevo.com:587"
        ;;
    5)
        prompt "SMTP host: "
        read -r SMTP_HOST
        prompt "SMTP port [587]: "
        read -r SMTP_PORT
        SMTP_PORT="${SMTP_PORT:-587}"
        prompt "SMTP username: "
        read -r SMTP_USER
        prompt "SMTP password: "
        read -rs SMTP_PASS
        echo ""
        MAUTIC_MAILER_DSN="smtp://${SMTP_USER}:${SMTP_PASS}@${SMTP_HOST}:${SMTP_PORT}"
        ;;
    6)
        info "SMTP skipped — you can configure it later in Mautic Settings > Email"
        ;;
    *)
        warn "Invalid choice, skipping SMTP setup"
        ;;
esac

# --- Generate DB Passwords ---
MYSQL_ROOT_PASSWORD=$(generate_password)
MYSQL_PASSWORD=$(generate_password)

echo ""
info "Generating configuration..."

# =============================================================================
# Write .env file
# =============================================================================
cat > .env << ENVFILE
# =============================================================================
# Mautic for Artists — Configuration
# Generated by setup.sh on $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# =============================================================================

# --- Artist Branding ---
ARTIST_NAME="${ARTIST_NAME}"
ARTIST_BRAND_COLOR="${ARTIST_BRAND_COLOR}"
ARTIST_LOGO_URL="${ARTIST_LOGO_URL}"
ARTIST_DOMAIN=${ARTIST_DOMAIN}

# --- Mautic Admin Account ---
MAUTIC_ADMIN_EMAIL=${MAUTIC_ADMIN_EMAIL}
MAUTIC_ADMIN_PASSWORD=${MAUTIC_ADMIN_PASSWORD}
MAUTIC_ADMIN_USERNAME=${MAUTIC_ADMIN_USERNAME}

# --- Mautic URL ---
MAUTIC_URL=${MAUTIC_URL}
MAUTIC_PORT=${MAUTIC_PORT}

# --- Email / SMTP ---
MAUTIC_MAILER_DSN=${MAUTIC_MAILER_DSN}

# --- Database (auto-generated) ---
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=mautic
MYSQL_USER=mautic
MYSQL_PASSWORD=${MYSQL_PASSWORD}
ENVFILE

info ".env file created"

# =============================================================================
# Build and start containers
# =============================================================================
echo ""
echo -e "${BOLD}Starting Mautic for Artists...${NC}"
echo -e "${DIM}This will build the Docker image and start all services.${NC}"
echo -e "${DIM}First run takes 2-5 minutes while Mautic installs.${NC}"
echo ""

docker compose build --quiet
info "Docker image built"

docker compose up -d
info "Containers started"

echo ""
info "Waiting for Mautic to initialize..."
echo -e "${DIM}This may take a few minutes on first run...${NC}"

# Wait for Mautic to be ready
ATTEMPTS=0
MAX_ATTEMPTS=60
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${MAUTIC_PORT}/s/login" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep 5
done

echo ""

if [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; then
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     Mautic for Artists is ready!         ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Dashboard:${NC}  ${MAUTIC_URL}/s/login"
    echo -e "  ${BOLD}Username:${NC}   ${MAUTIC_ADMIN_USERNAME}"
    echo -e "  ${BOLD}Password:${NC}   (the one you entered)"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo "    1. Log in and explore the pre-built email templates"
    echo "    2. Create a signup form (Components > Forms > New)"
    echo "    3. Review and activate the Welcome campaign"
    echo "    4. Add the signup form to your website"
    echo ""
    echo -e "  ${DIM}Docs: https://github.com/opensourceartist/mautic-for-artists/tree/main/docs${NC}"
    echo ""
else
    warn "Mautic is still starting up. Check status with:"
    echo "    docker compose logs -f mautic_web"
    echo ""
    echo "  Once ready, visit: ${MAUTIC_URL}/s/login"
fi
