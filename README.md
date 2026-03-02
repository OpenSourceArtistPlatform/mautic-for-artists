# Mautic for Artists

**Pre-configured email marketing for musicians.** One setup script, and you're ready to start building your fan list.

Mautic for Artists packages [Mautic](https://www.mautic.org/) — the leading open source marketing automation platform — with artist-specific email templates, fan segments, and a welcome campaign. Everything is containerized with Docker for a clean, reproducible setup.

## What's Included

- **4 email templates** — Welcome, Newsletter, Show Announcement, New Release (all customizable)
- **2 landing page themes** — Email signup page and release promo page
- **3 fan segments** — All Fans, Engaged Fans, New Subscribers
- **Welcome campaign** — Automatically sends a welcome email to new fans (draft, activate when ready)
- **Custom fan fields** — Track where fans discovered you (website, show, social media, referral)
- **Your branding** — Set your colors and logo once, applied everywhere

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) (v2)
- A server or local machine with at least 2GB RAM
- (Optional) An SMTP provider for sending emails (Mailgun, SES, SendGrid, or Brevo)

## Quick Start

```bash
git clone https://github.com/opensourceartist/mautic-for-artists.git
cd mautic-for-artists
./setup.sh
```

The setup wizard will ask for your artist name, brand color, admin credentials, and SMTP details. Once complete, your Mautic dashboard will be available at `http://localhost:8080`.

### Manual Setup

If you prefer to configure manually:

```bash
cp .env.example .env
# Edit .env with your settings
docker compose up -d
```

## Email Templates

| Template | Use Case | Theme |
|----------|----------|-------|
| Welcome to the Family | New fan signup | `artist-welcome` |
| Fan Update | Regular newsletter | `artist-newsletter` |
| Show Announcement | Tour/show dates | `artist-event` |
| New Release | Singles, EPs, albums | `artist-promo` |

All templates use your brand color and logo automatically. Edit the content in Mautic's drag-and-drop email builder.

## Landing Pages

| Theme | Use Case |
|-------|----------|
| `artist-signup` | Fan list signup with benefits |
| `artist-release` | Release promo with streaming links |

Create a new landing page in Mautic, select one of these themes, and add your Mautic form.

## Fan Segments

| Segment | Description |
|---------|-------------|
| All Fans | Everyone on your list |
| Engaged Fans | Fans who opened 3+ emails |
| New Subscribers | Fans added in the last 30 days |

## Documentation

- [Quick Start Guide](docs/quickstart.md) — Detailed setup walkthrough
- [SMTP Setup](docs/smtp-setup.md) — Provider-specific email configuration
- [Customization](docs/customization.md) — Branding, themes, and fields
- [Managed Platform](docs/managed-platform.md) — Full-service option

## Architecture

```
docker compose up -d
├── db              — MySQL 8.0 (data persistence)
├── mautic_web      — Mautic web UI + API (port 8080)
├── mautic_cron     — Scheduled tasks (segments, campaigns, emails)
└── mautic_worker   — Message queue processor
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting themes, reporting bugs, and development setup.

## The Open Source Artist Platform

Mautic for Artists is part of **The Open Source Artist Platform** — a managed multi-service platform for musicians that includes email marketing, website hosting, social media management, and more. [Learn more](docs/managed-platform.md).

## License

[GPL-3.0](LICENSE) — Same license as Mautic.
