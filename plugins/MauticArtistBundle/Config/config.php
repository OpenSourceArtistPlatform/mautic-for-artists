<?php

return [
    'name'        => 'Mautic for Artists',
    'description' => 'Whitelabel branding for Mautic for Artists',
    'version'     => '1.0.0',
    'author'      => 'Open Source Artist',
    'services'    => [
        'events' => [
            'mautic.artist.inject_assets_subscriber' => [
                'class' => \MauticPlugin\MauticArtistBundle\EventListener\InjectAssetsSubscriber::class,
            ],
        ],
    ],
];
