FROM mautic/mautic:5-apache

LABEL maintainer="Open Source Artist <hello@opensourceartist.com>"
LABEL description="Mautic for Artists — Pre-configured email marketing for musicians"

# Copy artist email themes
COPY themes/artist-welcome/  /var/www/html/docroot/themes/artist-welcome/
COPY themes/artist-newsletter/ /var/www/html/docroot/themes/artist-newsletter/
COPY themes/artist-event/    /var/www/html/docroot/themes/artist-event/
COPY themes/artist-promo/    /var/www/html/docroot/themes/artist-promo/

# Copy artist landing page themes
COPY themes/artist-signup/   /var/www/html/docroot/themes/artist-signup/
COPY themes/artist-release/  /var/www/html/docroot/themes/artist-release/

# Copy system theme overrides (login page, navbar, head)
COPY themes/system/ /var/www/html/docroot/themes/system/

# Copy MauticArtistBundle plugin (admin branding)
COPY plugins/MauticArtistBundle/ /var/www/html/docroot/plugins/MauticArtistBundle/

# Copy placeholder logo and custom favicon
COPY assets/placeholder-logo.png /var/www/html/docroot/media/images/placeholder-logo.png
COPY assets/favicon.ico /var/www/html/docroot/media/images/favicon.ico

# Copy entrypoint and seed scripts
COPY docker/entrypoint-artist.sh /entrypoint-artist.sh
COPY docker/seed-mautic.sh      /seed-mautic.sh
COPY docker/wait-for-it.sh      /wait-for-it.sh

RUN chmod +x /entrypoint-artist.sh /seed-mautic.sh /wait-for-it.sh

# Set correct ownership for themes, plugin, and media
RUN chown -R www-data:www-data \
    /var/www/html/docroot/themes/artist-welcome \
    /var/www/html/docroot/themes/artist-newsletter \
    /var/www/html/docroot/themes/artist-event \
    /var/www/html/docroot/themes/artist-promo \
    /var/www/html/docroot/themes/artist-signup \
    /var/www/html/docroot/themes/artist-release \
    /var/www/html/docroot/themes/system \
    /var/www/html/docroot/plugins/MauticArtistBundle \
    /var/www/html/docroot/media/images/placeholder-logo.png \
    /var/www/html/docroot/media/images/favicon.ico

ENTRYPOINT ["/entrypoint-artist.sh"]
CMD ["apache2-foreground"]
