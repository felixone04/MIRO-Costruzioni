import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/lightbox.dart';
import '../widgets/site_scaffold.dart';

/// I servizi: in alto le voci come filtri discreti, sotto il servizio scelto
/// con descrizione, foto e i lavori collegati.
class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key, this.initial});

  /// Id del servizio da mostrare all'apertura (es. da un link).
  final String? initial;

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  int? _i;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final list = s.activeServices;
    final initial = list.indexWhere((e) => e.id == widget.initial);
    final i = (_i ?? (initial < 0 ? 0 : initial)).clamp(
      0,
      list.isEmpty ? 0 : list.length - 1,
    );

    return SiteScaffold(
      current: '/servizi',
      children: [
        PageHeader(
          kicker: c.servicesKicker,
          title: c.servicesTitle,
          text: c.servicesText,
          bottom: list.isEmpty
              ? null
              : QuietFilters(
                  options: [for (final e in list) e.title],
                  selected: i,
                  onSelect: (n) => setState(() => _i = n),
                ),
        ),
        if (list.isNotEmpty)
          Section(
            top: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 550),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(a),
                  child: child,
                ),
              ),
              layoutBuilder: (cur, prev) => Stack(
                alignment: Alignment.topLeft,
                children: [...prev, ?cur],
              ),
              child: _ServiceView(key: ValueKey(list[i].id), service: list[i]),
            ),
          ),
      ],
    );
  }
}

class _ServiceView extends StatelessWidget {
  const _ServiceView({super.key, required this.service});
  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final wide = context.w >= 900;
    // I lavori delle categorie collegate al servizio.
    final projects = s.publishedProjects
        .where((p) => service.categories.contains(p.category))
        .toList();
    final photos = <ProjectPhoto>[
      for (final p in projects)
        for (final f in p.photos.take(2))
          ProjectPhoto(
            url: f.url,
            caption: [
              p.title,
              f.caption,
            ].where((e) => e.isNotEmpty).join(' · '),
          ),
    ].take(6).toList();

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(service.title, style: siteHead(context.fluid(34, 54))),
        const SizedBox(height: 18),
        Text(
          service.text,
          style: siteBody(context.fluid(16, 18), color: Site.muted),
        ),
        if (service.points.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in service.points)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Site.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(p, style: siteBody(14, height: 1.3)),
                ),
            ],
          ),
        ],
        if (projects.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text('Lavori di questo tipo', style: siteBody(14, color: Site.muted)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 18,
            children: [
              for (final p in projects.take(4))
                HoverLink(
                  p.title,
                  arrow: true,
                  onTap: () => context.go('/progetti/${p.id}'),
                  style: siteLabel(15, color: Site.accentDeep),
                ),
            ],
          ),
        ],
      ],
    );

    final image = AspectRatio(
      aspectRatio: wide ? 4 / 3.3 : 16 / 11,
      child: Rounded(
        radius: context.isPhone ? 20 : 28,
        child: PhotoImage(service.image),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: text),
              const SizedBox(width: 70),
              Expanded(flex: 6, child: image),
            ],
          )
        else ...[
          image,
          const SizedBox(height: 26),
          text,
        ],
        if (photos.isNotEmpty) ...[
          SizedBox(height: context.fluid(48, 80)),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 900
                  ? 3
                  : (box.maxWidth >= 520 ? 2 : 1);
              final gap = context.fluid(12, 20);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var n = 0; n < photos.length; n++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 90 * (n % cols)),
                        child: _Thumb(
                          photo: photos[n],
                          onTap: () => openLightbox(context, photos, n),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({required this.photo, required this.onTap});
  final ProjectPhoto photo;
  final VoidCallback onTap;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.zoomIn,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Rounded(
          radius: Radii.card,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: _hover ? 1.06 : 1,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                child: PhotoImage(widget.photo.url),
              ),
              // La didascalia sale dal basso al passaggio del mouse.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _hover ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      widget.photo.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: siteBody(13.5, color: Colors.white, height: 1.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
