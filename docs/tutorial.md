# Your First Fan Campaign: A Step-by-Step Tutorial

This tutorial walks you through everything from your first login to sending your first real email to fans. Set aside about 45 minutes and follow along — by the end, you'll have a working signup page, an automated welcome email, and your first broadcast sent.

**Prerequisites:** Before starting, complete the [Quick Start Guide](quickstart.md) and [SMTP setup](smtp-setup.md). You should be able to log into Mautic and send email.

---

## 1. Get Oriented — Your Mautic Dashboard

*~3 minutes*

Log into Mautic at `http://your-domain:8080/s/login` with the admin credentials you created during setup.

Take a quick look at the sidebar. These are the sections you'll use most:

- **Contacts** — Your fan list and segments (groups of fans)
- **Campaigns** — Automated sequences that send emails based on triggers
- **Components** — Emails, forms, and landing pages
- **Settings** (gear icon) — Configuration and custom fields

Verify that the pre-seeded content is in place:

1. Go to **Components > Emails** — you should see 4 draft templates: Welcome to the Family, New Release, Show Announcement, and Fan Update
2. Go to **Contacts > Segments** — you should see 3 segments: All Fans, Engaged Fans, and New Subscribers
3. Go to **Campaigns** — you should see one draft campaign: Welcome New Fans

If any of these are missing, re-run the seed script. See the [Quick Start Guide](quickstart.md) for details.

---

## 2. Customize Your Welcome Email

*~5 minutes*

The "Welcome to the Family" email is the first thing new fans will receive. Let's make it yours.

1. Go to **Components > Emails**
2. Click **Welcome to the Family** to open it
3. Edit the **Subject** field — something like "Welcome! You're officially in the crew"
4. Click **Builder** to open the GrapesJS drag-and-drop editor

In the builder:

5. Click on any text block to edit it. Write a short welcome message in your voice — thank them for joining, tell them what to expect
6. Where you see `{contactfield=firstname}`, leave it as-is. Mautic replaces this with each fan's actual first name when the email is sent. For example, "Hey `{contactfield=firstname}`!" becomes "Hey Sarah!" See [Customization Guide — Placeholder Variables](customization.md#placeholder-variables) for the full list
7. Update the CTA button link to point to your latest release, merch store, or website
8. Update the social media URLs in the footer to your actual profiles

Click **Close Builder**, then **Save & Close**. Don't publish yet — we'll do that after setting up the full flow.

---

## 3. Create Your Signup Form

*~5 minutes*

A form is how fans join your list. Let's create one.

1. Go to **Components > Forms > New**
2. Set the name to something like "Fan Signup"
3. Add these fields:
   - **Email** — set as required
   - **First Name**
   - **Fan Source** — choose "Select" type and map it to the pre-seeded `fan_source` custom field. This tracks where fans found you (Website, Live Show, Social Media, Referral)
4. Change the submit button text to **Join the Family**

Now add a form action so new signups are added to your list:

5. Click the **Actions** tab
6. Add action: **Modify contact's segments**
7. Set it to add the contact to **All Fans**
8. Set a success message like "You're in! Check your inbox for a welcome email."
9. Click **Save & Close**

---

## 4. Build Your Signup Landing Page

*~7 minutes*

A landing page gives you a shareable URL where fans can sign up — no website needed.

1. Go to **Components > Landing Pages > New**
2. Enter a title like "Join the Family"
3. Select the **Artist Signup** theme
4. Click **Builder** to open the page editor

In the builder:

5. Update the hero text with your artist name and a compelling pitch — "Get exclusive updates, early access to tickets, and new music straight to your inbox"
6. To embed your form, drag a **Mautic Form** component onto the page. Select the form you just created in Section 3
7. Update the benefits section — list what fans get by signing up (early ticket access, behind-the-scenes content, release announcements)
8. Update social links to your profiles

Click **Close Builder**.

9. Toggle **Published** to Yes
10. Click **Save & Close**

Note the page URL — this is what you'll share with fans. You'll find it on the landing page detail view. Share it on social media, link it from your website, or print it as a QR code for shows.

---

## 5. Activate Your Welcome Campaign

*~5 minutes*

Right now, the welcome email and campaign are both in draft mode. Let's activate them in the right order.

**First, publish the email:**

1. Go to **Components > Emails**
2. Click **Welcome to the Family**
3. Toggle **Published** to Yes
4. **Save & Close**

**Then, publish the campaign:**

5. Go to **Campaigns**
6. Click **Welcome New Fans**
7. Toggle **Published** to Yes
8. **Save & Close**

Here's what happens now when a fan signs up:

- Fan submits your signup form
- Form action adds them to the **All Fans** segment
- The **Welcome New Fans** campaign detects the new contact in the segment
- Mautic sends the **Welcome to the Family** email

> **Note:** Mautic processes campaigns via a cron job that runs every 60 seconds. There may be a 1-2 minute delay between signup and email delivery. This is normal.

---

## 6. Test the Full Flow

*~5 minutes*

Let's make sure everything works end to end.

1. Open your signup landing page URL in an **incognito/private browser window** (so Mautic treats you as a new visitor)
2. Fill out the form with a real email address you can check
3. Submit the form — you should see your success message

Now verify in Mautic:

4. Go to **Contacts** — your new contact should appear with the email and first name you entered
5. Click the contact to see their timeline — you should see "Segment membership added: All Fans"
6. Wait 1-2 minutes for the cron job to process
7. Check your email inbox — the welcome email should arrive

**If the email doesn't arrive:**

- Check your spam/junk folder
- Look at the contact timeline in Mautic — do you see "Email sent"?
- Check `docker compose logs mautic_web` for SMTP errors
- Review your [SMTP setup](smtp-setup.md) to confirm your provider is configured correctly

---

## 7. Import Your Existing Fans

*~5 minutes*

If you already have fans from a previous email list, mailing list signup sheet, or spreadsheet, you can import them.

Prepare a CSV file with columns for the data you have. For example:

```csv
email,firstname,fan_source
sarah@example.com,Sarah,show
mike@example.com,Mike,social_media
jen@example.com,Jen,website
```

The column names should match Mautic field aliases: `email`, `firstname`, `fan_source`.

To import:

1. Go to **Contacts**
2. Click the **Import** button (upload icon)
3. Upload your CSV file
4. Map each CSV column to the corresponding Mautic field
5. Under segment options, add imported contacts to **All Fans**
6. Run the import

> **Note:** The Welcome New Fans campaign will **not** fire retroactively for imported contacts. Campaigns only trigger for contacts added after the campaign is published. If you want to send these fans a welcome email, use a broadcast (covered in the next section).

---

## 8. Send Your First Broadcast

*~7 minutes*

There are two types of emails in Mautic:

- **Template emails** — sent by campaigns and automations (like your welcome email)
- **Segment emails** — broadcast to an entire segment at once (newsletters, announcements)

Let's send your first broadcast.

1. Go to **Components > Emails**
2. Click **New** and select **New Segment Email**
3. Enter a name like "First Newsletter" and a subject line
4. Select the **artist-newsletter** theme
5. Choose **All Fans** as the target segment
6. Click **Builder** to customize the content

Write your first newsletter — a quick intro, what you've been working on, upcoming shows, a link to your latest release. Keep it short and personal.

7. Click **Close Builder** and **Save**

Before sending to everyone, send a test:

8. Click **Send Example** at the top of the email view
9. Enter your own email address and send
10. Check your inbox — review how it looks, check links, proofread

When you're satisfied:

11. Toggle **Published** to Yes
12. Click **Save & Close**

Mautic will begin sending to all contacts in the All Fans segment. Monitor delivery by returning to the email view — you'll see stats for sends, opens, and clicks.

---

## 9. Understand Your Segments

*~3 minutes*

Segments are dynamic groups of contacts that update automatically based on filters. As your fan list grows, segments let you send the right message to the right fans.

Review your three pre-built segments at **Contacts > Segments**:

- **All Fans** — Every contact on your list. No filters, so every contact is included automatically. Use this for broadcasts to your entire audience.
- **New Subscribers** — Fans who signed up in the last 30 days. This uses a `date_added` filter set to the last 30 days. Useful for onboarding sequences.
- **Engaged Fans** — This segment is a placeholder. It was created without a filter so you can define what "engaged" means for you.

To set up the Engaged Fans filter:

1. Go to **Contacts > Segments** and click **Engaged Fans**
2. Click the **Filters** tab
3. Add a filter: choose **Email read count** as the field, set the operator to **greater than**, and enter a value like `3`
4. **Save & Close**

Mautic will automatically populate this segment with contacts who have opened 3 or more of your emails. As your list grows, you can target engaged fans with exclusive content like pre-sale codes or behind-the-scenes updates.

For more ideas on custom segments, see the [Customization Guide — Adding Custom Segments](customization.md#adding-custom-segments).

---

## 10. What's Next

*~2 minutes*

You've accomplished a lot. Here's what you now have running:

- A signup landing page fans can visit to join your list
- An automated welcome email that goes out to every new fan
- Your first newsletter broadcast sent to your audience
- Segments that organize your fans automatically

**Ideas to keep going:**

- **Share your signup URL everywhere** — social media bios, website header, Linktree
- **Print a QR code** for your signup page and display it at shows, on merch tables, or on posters
- **Create a release campaign** — duplicate the Welcome New Fans campaign and modify it to announce your next single or album
- **Build more landing pages** — use the **Artist Release** theme for album launches, pre-saves, or ticket sales
- **Segment your audience** — create segments for fans in specific cities, fans from live shows, or fans who engage with every email

**Further reading:**

- [Customization Guide](customization.md) — deeper branding, themes, custom fields, and segments
- [SMTP Setup](smtp-setup.md) — email delivery troubleshooting and DNS configuration
- [The Open Source Artist Platform](managed-platform.md) — a fully managed version with website, social scheduling, analytics, and more
- [Mautic Official Documentation](https://docs.mautic.org/) — the full reference for everything Mautic can do
