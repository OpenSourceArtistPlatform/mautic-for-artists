# SMTP / Email Provider Setup

To send emails from Mautic, you need an SMTP provider. This guide covers the most popular options.

## Choosing a Provider

| Provider | Free Tier | Best For |
|----------|-----------|----------|
| [Mailgun](https://www.mailgun.com/) | 1,000 emails/month (trial) | Developers, reliable delivery |
| [Amazon SES](https://aws.amazon.com/ses/) | 3,000 emails/month (free tier) | Cost-effective at scale |
| [SendGrid](https://sendgrid.com/) | 100 emails/day | Easy setup, good dashboard |
| [Brevo](https://www.brevo.com/) | 300 emails/day | EU-based, generous free tier |

## Configuration

### Option A: During Setup

When you run `./setup.sh`, select your provider and enter your credentials. The DSN is configured automatically.

### Option B: Edit .env

Set the `MAUTIC_MAILER_DSN` variable in your `.env` file, then restart:

```bash
docker compose down && docker compose up -d
```

### Option C: Mautic UI

1. Log into Mautic
2. Go to **Settings** (gear icon) > **Configuration** > **Email Settings**
3. Configure your SMTP settings there

---

## Provider-Specific Setup

### Mailgun

1. Sign up at [mailgun.com](https://www.mailgun.com/)
2. Add and verify your sending domain
3. Add DNS records:
   - **TXT** record for SPF
   - **TXT** record for DKIM
   - **MX** records (if receiving)
4. Get your SMTP credentials from **Sending > Domain settings > SMTP credentials**

```env
MAUTIC_MAILER_DSN=smtp://postmaster@mg.yourdomain.com:YOUR_PASSWORD@smtp.mailgun.org:587
```

### Amazon SES

1. Sign up for [AWS](https://aws.amazon.com/) and navigate to SES
2. Verify your sending domain (add DKIM + SPF records)
3. If in sandbox mode, also verify recipient emails
4. Create SMTP credentials in **SMTP settings**

```env
MAUTIC_MAILER_DSN=smtp://YOUR_SMTP_USERNAME:YOUR_SMTP_PASSWORD@email-smtp.us-east-1.amazonaws.com:587
```

Replace `us-east-1` with your SES region.

### SendGrid

1. Sign up at [sendgrid.com](https://sendgrid.com/)
2. Complete Sender Authentication (domain verification)
3. Create an API key with "Mail Send" permission

```env
MAUTIC_MAILER_DSN=smtp://apikey:YOUR_API_KEY@smtp.sendgrid.net:587
```

Note: The username is literally `apikey` (not your email).

### Brevo (formerly Sendinblue)

1. Sign up at [brevo.com](https://www.brevo.com/)
2. Go to **Settings > SMTP & API**
3. Get your SMTP key

```env
MAUTIC_MAILER_DSN=smtp://YOUR_EMAIL:YOUR_SMTP_KEY@smtp-relay.brevo.com:587
```

### Other SMTP

For any SMTP server:

```env
MAUTIC_MAILER_DSN=smtp://USERNAME:PASSWORD@SMTP_HOST:587
```

---

## DNS Records

Regardless of provider, configure these DNS records for your sending domain:

### SPF Record
```
TXT  @  v=spf1 include:YOUR_PROVIDER_SPF ~all
```

### DKIM Record
Your provider will give you the DKIM key to add as a TXT record.

### DMARC Record
```
TXT  _dmarc  v=DMARC1; p=none; rua=mailto:dmarc@yourdomain.com
```

Start with `p=none` (monitoring), then move to `p=quarantine` or `p=reject` once you've verified deliverability.

## Testing

After configuration:

1. Log into Mautic
2. Go to **Components > Emails**
3. Open any email template
4. Click **Send Example** to send a test to yourself
5. Check your inbox (and spam folder)

If emails don't arrive, check:
- `docker compose logs mautic_web` for SMTP errors
- DNS propagation (can take up to 48 hours)
- Provider dashboard for bounces or blocks
