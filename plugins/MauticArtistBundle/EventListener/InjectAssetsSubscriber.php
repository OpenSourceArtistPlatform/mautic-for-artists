<?php

namespace MauticPlugin\MauticArtistBundle\EventListener;

use Mautic\CoreBundle\CoreEvents;
use Mautic\CoreBundle\Event\CustomAssetsEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class InjectAssetsSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            CoreEvents::VIEW_INJECT_CUSTOM_ASSETS => ['onInjectCustomAssets', 0],
        ];
    }

    public function onInjectCustomAssets(CustomAssetsEvent $event): void
    {
        $event->addStylesheet('plugins/MauticArtistBundle/Assets/css/artist-admin.css');

        $event->addScriptDeclaration("
            document.addEventListener('DOMContentLoaded', function() {
                if (!document.title.includes('Mautic for Artists')) {
                    document.title = document.title.replace(/Mautic$/, 'Mautic for Artists');
                }
            });
        ");
    }
}
