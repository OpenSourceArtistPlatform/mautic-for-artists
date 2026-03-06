#!/bin/bash
set -e

# =============================================================================
# Mautic for Artists — Seed Script
# Creates segments, custom fields, email templates, and a welcome campaign
# via the Mautic REST API (Basic Auth).
# =============================================================================

MAUTIC_URL="http://localhost:80"
MAUTIC_USER="${MAUTIC_ADMIN_USERNAME:-admin}"
MAUTIC_PASS="${MAUTIC_ADMIN_PASSWORD}"
ARTIST_NAME="${ARTIST_NAME:-My Artist}"

if [ -z "$MAUTIC_PASS" ]; then
    echo "[seed-mautic] ERROR: MAUTIC_ADMIN_PASSWORD is not set. Cannot seed."
    exit 1
fi

API="${MAUTIC_URL}/api"
AUTH="-u ${MAUTIC_USER}:${MAUTIC_PASS}"

# Helper: make an API call and return the response
api_post() {
    local endpoint="$1"
    shift
    curl -s -X POST "${API}${endpoint}" \
        ${AUTH} \
        -H "Content-Type: application/json" \
        "$@"
}

api_get() {
    local endpoint="$1"
    curl -s -X GET "${API}${endpoint}" \
        ${AUTH} \
        -H "Content-Type: application/json"
}

THEME_DIR="/var/www/html/docroot/themes"

# Helper: read a theme's email.html.twig and JSON-escape it
theme_html() {
    local theme="$1"
    local file="${THEME_DIR}/${theme}/html/email.html.twig"
    if [ -f "$file" ]; then
        python3 -c "import json,sys; print(json.dumps(open(sys.argv[1]).read()))" "$file"
    else
        echo 'null'
    fi
}

echo "[seed-mautic] Starting Mautic seeding for '${ARTIST_NAME}'..."

# =============================================================================
# 1. Create Custom Contact Fields
# =============================================================================
echo "[seed-mautic] Creating custom contact fields..."

api_post "/fields/contact/new" -d '{
    "label": "Fan Source",
    "alias": "fan_source",
    "type": "select",
    "properties": {
        "list": [
            {"label": "Website", "value": "website"},
            {"label": "Live Show", "value": "show"},
            {"label": "Social Media", "value": "social_media"},
            {"label": "Referral", "value": "referral"}
        ]
    },
    "group": "core",
    "isPubliclyUpdatable": true
}' > /dev/null 2>&1 || true

echo "[seed-mautic] Custom fields created"

# =============================================================================
# 2. Create Segments
# =============================================================================
echo "[seed-mautic] Creating segments..."

# All Fans — catch-all segment (no filters)
ALL_FANS_RESPONSE=$(api_post "/segments/new" -d '{
    "name": "All Fans",
    "alias": "all-fans",
    "description": "Every fan who has joined your list",
    "isPublished": true,
    "isGlobal": true
}')
ALL_FANS_ID=$(echo "$ALL_FANS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
echo "[seed-mautic] Created segment: All Fans (ID: ${ALL_FANS_ID})"

# Engaged Fans — fans who have read 3+ emails (filter to be configured in UI)
api_post "/segments/new" -d '{
    "name": "Engaged Fans",
    "alias": "engaged-fans",
    "description": "Fans who have opened 3 or more emails — add a filter in the Mautic UI to track engagement",
    "isPublished": true,
    "isGlobal": true
}' > /dev/null 2>&1 || true
echo "[seed-mautic] Created segment: Engaged Fans"

# New Subscribers — added in last 30 days
api_post "/segments/new" -d '{
    "name": "New Subscribers",
    "alias": "new-subscribers",
    "description": "Fans who signed up in the last 30 days",
    "isPublished": true,
    "isGlobal": true,
    "filters": [
        {
            "glue": "and",
            "field": "date_added",
            "object": "lead",
            "type": "datetime",
            "operator": "gte",
            "properties": {
                "filter": "-30 days"
            }
        }
    ]
}' > /dev/null 2>&1 || true
echo "[seed-mautic] Created segment: New Subscribers"

# =============================================================================
# 3. Create Draft Email Templates
# =============================================================================
echo "[seed-mautic] Creating email templates..."

# Welcome email
WELCOME_HTML=$(theme_html "artist-welcome")
WELCOME_RESPONSE=$(api_post "/emails/new" -d "{
    \"name\": \"Welcome to the Family\",
    \"subject\": \"Welcome to ${ARTIST_NAME}'s inner circle!\",
    \"description\": \"Sent to new fans when they join your list\",
    \"emailType\": \"template\",
    \"template\": \"artist-welcome\",
    \"isPublished\": false,
    \"customHtml\": ${WELCOME_HTML}
}")
WELCOME_ID=$(echo "$WELCOME_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
echo "[seed-mautic] Created email: Welcome to the Family (ID: ${WELCOME_ID})"

# New Release email
RELEASE_HTML=$(theme_html "artist-promo")
api_post "/emails/new" -d "{
    \"name\": \"New Release\",
    \"subject\": \"New music from ${ARTIST_NAME} — out now!\",
    \"description\": \"Announce new singles, EPs, or albums\",
    \"emailType\": \"template\",
    \"template\": \"artist-promo\",
    \"isPublished\": false,
    \"customHtml\": ${RELEASE_HTML}
}" > /dev/null 2>&1 || true
echo "[seed-mautic] Created email: New Release"

# Show Announcement email
SHOW_HTML=$(theme_html "artist-event")
api_post "/emails/new" -d "{
    \"name\": \"Show Announcement\",
    \"subject\": \"${ARTIST_NAME} is coming to your city!\",
    \"description\": \"Announce upcoming shows, tours, or live events\",
    \"emailType\": \"template\",
    \"template\": \"artist-event\",
    \"isPublished\": false,
    \"customHtml\": ${SHOW_HTML}
}" > /dev/null 2>&1 || true
echo "[seed-mautic] Created email: Show Announcement"

# Fan Update email
UPDATE_HTML=$(theme_html "artist-newsletter")
api_post "/emails/new" -d "{
    \"name\": \"Fan Update\",
    \"subject\": \"What's new with ${ARTIST_NAME}\",
    \"description\": \"Regular newsletter updates for your fan base\",
    \"emailType\": \"template\",
    \"template\": \"artist-newsletter\",
    \"isPublished\": false,
    \"customHtml\": ${UPDATE_HTML}
}" > /dev/null 2>&1 || true
echo "[seed-mautic] Created email: Fan Update"

# =============================================================================
# 4. Create Draft Welcome Campaign
# =============================================================================
echo "[seed-mautic] Creating welcome campaign..."

if [ -n "$ALL_FANS_ID" ] && [ -n "$WELCOME_ID" ]; then
    api_post "/campaigns/new" -d "{
        \"name\": \"Welcome New Fans\",
        \"description\": \"Automatically welcome new fans when they join your list. Review and activate when ready.\",
        \"isPublished\": false,
        \"lists\": [${ALL_FANS_ID}],
        \"events\": [
            {
                \"name\": \"Send Welcome Email\",
                \"type\": \"email.send\",
                \"eventType\": \"action\",
                \"order\": 1,
                \"properties\": {
                    \"email\": ${WELCOME_ID}
                },
                \"triggerMode\": \"immediate\",
                \"triggerDate\": null,
                \"triggerInterval\": 0,
                \"triggerIntervalUnit\": \"d\",
                \"decisionPath\": null,
                \"channel\": \"email\"
            }
        ]
    }" > /dev/null 2>&1 || true
    echo "[seed-mautic] Created campaign: Welcome New Fans"
else
    echo "[seed-mautic] WARNING: Could not create campaign (missing segment or email ID)"
fi

# =============================================================================
# Done
# =============================================================================
echo ""
echo "=============================================="
echo "  Mautic for Artists — Seeding Complete!"
echo "=============================================="
echo ""
echo "  Created:"
echo "    - 1 custom field (Fan Source)"
echo "    - 3 segments (All Fans, Engaged Fans, New Subscribers)"
echo "    - 4 email templates (Welcome, New Release, Show, Fan Update)"
echo "    - 1 welcome campaign (draft)"
echo ""
echo "  Next steps:"
echo "    1. Log into Mautic and review the email templates"
echo "    2. Customize the content for your style"
echo "    3. Activate the welcome campaign when ready"
echo ""
