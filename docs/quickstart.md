# Quick Start Guide

This guide walks you through setting up Mautic for Artists from scratch.

## Prerequisites

Before you begin, make sure you have:

1. **Docker** — [Install Docker](https://docs.docker.com/get-docker/)
2. **Docker Compose v2** — Usually included with Docker Desktop. On Linux, install [Docker Compose plugin](https://docs.docker.com/compose/install/linux/).
3. **A server** — At least 2GB RAM. Works on any VPS (DigitalOcean, Hetzner, Linode, etc.) or locally.

Verify your installation:

```bash
docker --version          # Docker version 24+ recommended
docker compose version    # Docker Compose version v2+
```

## Step 1: Clone the Repository

```bash
git clone https://github.com/opensourceartist/mautic-for-artists.git
cd mautic-for-artists
```

## Step 2: Run the Setup Wizard

```bash
./setup.sh
```

The wizard will ask you for:

| Prompt | What to Enter |
|--------|---------------|
| Artist name | Your artist or band name |
| Brand color | A hex color code (e.g., `#FF5500`) |
| Logo URL | URL to your logo, or press Enter for the placeholder |
| Domain | Your domain (or `localhost` for local testing) |
| Port | The port for the web UI (default: `8080`) |
| Admin email | Your email for the admin account |
| Admin password | A strong password (min 8 characters) |
| SMTP provider | Choose your email provider or skip for now |

The wizard generates a `.env` file, builds the Docker image, and starts all services.

## Step 3: Access Mautic

Once setup completes (2-5 minutes on first run), visit:

```
http://localhost:8080/s/login
```

Log in with the admin credentials you chose during setup.

## Step 4: Explore Your Pre-Built Content

After login, you'll find:

### Email Templates
Navigate to **Components > Emails**. You'll see 4 draft templates:
- Welcome to the Family
- Fan Update
- Show Announcement
- New Release

Click any template to preview and customize it in the drag-and-drop editor.

### Segments
Navigate to **Contacts > Segments**. You'll see:
- All Fans
- Engaged Fans
- New Subscribers

### Welcome Campaign
Navigate to **Campaigns**. The "Welcome New Fans" campaign is ready in draft mode. Review it and publish when you're ready.

## Step 5: Create a Signup Form

1. Go to **Components > Forms > New**
2. Add fields: Email (required), First Name
3. Set the action to "Add contact to segment" → "All Fans"
4. Save and copy the embed code

## Step 6: Add the Form to Your Website

Paste the Mautic form embed code into your website's HTML. Alternatively, create a landing page in Mautic:

1. Go to **Components > Landing Pages > New**
2. Choose the **Artist Signup** theme
3. Add your form to the page
4. Publish and share the URL

## Common Operations

### Stop Mautic
```bash
docker compose down
```

### Restart Mautic
```bash
docker compose restart
```

### View Logs
```bash
docker compose logs -f mautic_web
```

### Update Brand Color
Edit `.env`, change `ARTIST_BRAND_COLOR`, then rebuild:
```bash
docker compose down
docker compose build
docker compose up -d
```

## Next Steps

- [Set up SMTP](smtp-setup.md) if you skipped it during setup
- [Customize your themes](customization.md)
- Read Mautic's official [documentation](https://docs.mautic.org/)
