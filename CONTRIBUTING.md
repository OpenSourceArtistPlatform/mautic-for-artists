# Contributing to Mautic for Artists

Thanks for your interest in contributing! This project is built for musicians by people who care about open source and independent music.

## Ways to Contribute

### Report Bugs

Found a bug? [Open an issue](https://github.com/opensourceartist/mautic-for-artists/issues/new?template=bug_report.yml) with:
- Steps to reproduce
- Expected vs. actual behavior
- Your environment (OS, Docker version)

### Suggest Features

Have an idea? [Open a feature request](https://github.com/opensourceartist/mautic-for-artists/issues/new?template=feature_request.yml) describing:
- The problem you're solving
- Your proposed solution
- Who benefits

### Submit Email Themes

New email themes are welcome! A good theme should:
- Use `{{BRAND_COLOR}}` and `{{LOGO_URL}}` placeholders for branding
- Work across major email clients (Gmail, Outlook, Apple Mail, Yahoo)
- Be mobile-responsive
- Follow the existing theme structure (`config.json` + `html/` directory)
- Include artist/musician-relevant content

### Submit Landing Page Themes

Landing page themes should:
- Use `data-section-wrapper` and `data-slot` attributes for GrapesJS builder compatibility
- Include `config.json` with `"features": ["page"]`
- Include `css/style.css` for styling
- Include `MauticFormBundle/Builder/style.html.twig` for form styling
- Be mobile-responsive

### Improve Documentation

Documentation improvements are always welcome. Fix typos, add examples, or write guides for common workflows.

## Development Setup

1. Fork and clone the repository
2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` with test values
4. Build and start:
   ```bash
   docker compose build
   docker compose up -d
   ```
5. Access Mautic at `http://localhost:8080`

### Testing Theme Changes

After modifying themes, rebuild the image:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Testing the Seed Script

To re-run the seed script (after deleting the marker file):

```bash
docker compose exec mautic_web rm -f /var/www/html/var/.artist-seeded
docker compose exec mautic_web /seed-mautic.sh
```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Test locally with `docker compose`
4. Submit a PR with a clear description of what changed and why

## Code Style

- Shell scripts: Use `shellcheck` for linting
- HTML emails: Test with [Litmus](https://www.litmus.com/) or [Email on Acid](https://www.emailonacid.com/) if possible
- Keep dependencies minimal — this project intentionally avoids build tools and frameworks

## License

By contributing, you agree that your contributions will be licensed under the [GPL-3.0 License](LICENSE).
