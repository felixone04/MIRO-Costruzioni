import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final list = s.activeServices;
    return SiteScaffold(
      current: '/servizi',
      children: [
        PageHero(
          kicker: c.servicesKicker,
          title: c.servicesTitle,
          text: c.servicesText,
          image: list.isNotEmpty ? list.first.image : c.ctaImage,
        ),
        Section(
          child: Column(
            children: [
              for (var i = 0; i < list.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == list.length - 1 ? 0 : context.fluid(70, 140),
                  ),
                  child: _ServiceBlock(
                    service: list[i],
                    number: i + 1,
                    flip: i.isOdd,
                  ),
                ),
            ],
          ),
        ),
        const Ticker(dark: true),
        const ProcessSection(),
        const CtaSection(),
      ],
    );
  }
}

/// Un servizio: foto grande con parallasse e testo, alternati.
class _ServiceBlock extends StatelessWidget {
  const _ServiceBlock({
    required this.service,
    required this.number,
    required this.flip,
  });
  final ServiceItem service;
  final int number;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final wide = context.w >= 900;
    final image = Reveal(
      child: AspectRatio(
        aspectRatio: wide ? 4 / 3.4 : 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ParallaxImage(service.image),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                color: Site.accent,
                padding: const EdgeInsets.all(14),
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: siteHead(
                    30,
                    weight: FontWeight.w700,
                    height: 1,
                    color: Site.onAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(
          child: Tag('Servizio', number: number.toString().padLeft(2, '0')),
        ),
        const SizedBox(height: 22),
        RevealTitle(service.title, style: siteHead(context.fluid(40, 72))),
        const SizedBox(height: 20),
        Reveal(
          delay: const Duration(milliseconds: 150),
          child: Text(service.text, style: siteBody(17, color: Site.muted)),
        ),
        if (service.points.isNotEmpty) ...[
          const SizedBox(height: 24),
          for (var i = 0; i < service.points.length; i++)
            Reveal(
              delay: Duration(milliseconds: 200 + i * 80),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Site.line)),
                ),
                child: Row(
                  children: [
                    Transform.rotate(
                      angle: 0.785,
                      child: Container(width: 7, height: 7, color: Site.accent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        service.points[i].toUpperCase(),
                        style: siteMono(12.5, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 30),
        Reveal(
          delay: const Duration(milliseconds: 300),
          child: SiteButton(
            'Richiedi un sopralluogo',
            kind: ButtonKind.dark,
            onTap: () => context.go(
              Uri(
                path: '/contatti',
                queryParameters: {'tipo': service.title},
              ).toString(),
            ),
          ),
        ),
      ],
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [image, const SizedBox(height: 32), text],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: flip
          ? [
              Expanded(flex: 5, child: text),
              const SizedBox(width: 80),
              Expanded(flex: 6, child: image),
            ]
          : [
              Expanded(flex: 6, child: image),
              const SizedBox(width: 80),
              Expanded(flex: 5, child: text),
            ],
    );
  }
}
