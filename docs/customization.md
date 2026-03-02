# Customization Guide

## Changing Your Branding

### Brand Color and Logo

Edit your `.env` file:

```env
ARTIST_BRAND_COLOR=#FF5500
ARTIST_LOGO_URL=https://yourdomain.com/logo.png
```

Then rebuild and restart:

```bash
docker compose down
docker compose build
docker compose up -d
```

The brand color and logo are applied to all `artist-*` themes at container startup.

### Uploading a Logo

You can also upload a logo through Mautic:

1. Log into Mautic
2. Go to any email template editor
3. Click the logo image and upload your file
4. Or upload via **Settings > Media** and reference the URL in `.env`

## Customizing Email Templates

### Using the Drag-and-Drop Editor

1. Go to **Components > Emails**
2. Click on a template (e.g., "Welcome to the Family")
3. Click **Builder** to open the visual editor
4. Edit text, images, buttons, and layout
5. Save when done

### Editing Theme HTML Directly

Theme files are in the `themes/` directory. Each email theme has:

```
themes/artist-welcome/
├── config.json           # Theme metadata
└── html/
    ├── base.html.twig    # Base HTML wrapper
    ├── message.html.twig # Web view template
    └── email.html.twig   # The email template
```

Edit `email.html.twig` to change the default HTML. After editing, rebuild:

```bash
docker compose down
docker compose build
docker compose up -d
```

### Placeholder Variables

These Mautic variables work in all templates:

| Variable | Description |
|----------|-------------|
| `{contactfield=firstname}` | Contact's first name |
| `{contactfield=lastname}` | Contact's last name |
| `{contactfield=email}` | Contact's email |
| `{subject}` | Email subject line |
| `{webview_url}` | Link to web version |
| `{unsubscribe_text}` | Unsubscribe link |

### Branding Placeholders

These are replaced at container startup:

| Placeholder | Replaced With |
|-------------|---------------|
| `{{BRAND_COLOR}}` | Value of `ARTIST_BRAND_COLOR` |
| `{{LOGO_URL}}` | Value of `ARTIST_LOGO_URL` |

## Creating a New Email Theme

1. Copy an existing theme:
   ```bash
   cp -r themes/artist-welcome themes/artist-mythem
   ```

2. Update `config.json`:
   ```json
   {
     "name": "My Custom Theme",
     "author": "Your Name",
     "authorUrl": "https://yoursite.com",
     "builder": ["grapesjsbuilder"],
     "features": ["email"]
   }
   ```

3. Edit `html/email.html.twig` with your design

4. Rebuild: `docker compose down && docker compose build && docker compose up -d`

## Customizing Landing Pages

### Using the Page Builder

1. Go to **Components > Landing Pages > New**
2. Select **Artist Signup** or **Artist Release** theme
3. Use the GrapesJS builder to customize
4. Add a Mautic form to the page

### Editing Landing Page CSS

Landing page themes include a CSS file:

```
themes/artist-signup/
├── config.json
├── css/
│   └── style.css         # Edit this for styling
└── html/
    ├── base.html.twig
    ├── message.html.twig
    ├── page.html.twig    # Page structure
    └── MauticFormBundle/
        └── Builder/
            └── style.html.twig  # Form styles
```

## Adding Custom Contact Fields

### Via the API (seed script)

Add fields to `docker/seed-mautic.sh`:

```bash
api_post "/fields/contact/new" -d '{
    "label": "Favorite Genre",
    "alias": "favorite_genre",
    "type": "select",
    "properties": {
        "list": [
            {"label": "Rock", "value": "rock"},
            {"label": "Hip Hop", "value": "hiphop"},
            {"label": "Electronic", "value": "electronic"}
        ]
    }
}'
```

### Via the Mautic UI

1. Go to **Settings > Custom Fields**
2. Click **New**
3. Configure the field type, options, and visibility

## Adding Custom Segments

### Via the Mautic UI

1. Go to **Contacts > Segments > New**
2. Name your segment
3. Add filters (e.g., "Fan Source equals show")
4. Save

### Segment Ideas for Musicians

- **Show Attendees** — Filter by `fan_source = show`
- **VIP Fans** — Filter by engagement score > threshold
- **Local Fans** — Filter by city or region
- **Genre Fans** — Filter by custom genre field
