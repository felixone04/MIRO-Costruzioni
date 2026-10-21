import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/compare_slider.dart';
import '../widgets/lightbox.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

// ================================================================== ELENCO

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key, this.category});
  final String? category;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  late String? _category = widget.category;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final all = s.publishedProjects;
    final cats = s.usedCategories;
    final category = cats.contains(_category) ? _category : null;
    final list = all
        .where((p) => category == null || p.category == category)
        .toList();
    final options = ['Tutti', ...cats];

    return SiteScaffold(
      current: '/progetti',
      children: [
        PageHeader(
          kicker: c.projectsKicker,
          title: c.projectsTitle,
          text: c.projectsText,
          bottom: QuietFilters(
            options: options,
            selected: category == null ? 0 : options.indexOf(category),
            onSelect: (i) =>
                setState(() => _category = i == 0 ? null : options[i]),
          ),
        ),
        Section(
          top: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, a) =>
                FadeTransition(opacity: a, child: child),
            child: KeyedSubtree(
              key: ValueKey(category),
              child: list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'Nessun progetto in questa categoria, per ora.',
                        style: siteBody(16, color: Site.muted),
                      ),
                    )
                  : ProjectGrid(projects: list, showSummary: true),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================= DETTAGLIO

class ProjectPage extends StatelessWidget {
  const ProjectPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.projectById(id);
    if (p == null || !p.published) {
      return SiteScaffold(
        current: '/progetti',
        children: [
          PageHeader(
            kicker: 'Progetti',
            title: 'Questo progetto\nnon c\'è più.',
            bottom: SiteButton(
              'Tutti i progetti',
              kind: ButtonKind.outline,
              onTap: () => context.go('/progetti'),
            ),
          ),
        ],
      );
    }
    final list = s.publishedProjects;
    final next = list.length > 1
        ? list[(list.indexWhere((e) => e.id == p.id) + 1) % list.length]
        : null;
    final wide = context.w >= 980;

    final facts = [
      ('Luogo', p.location),
      ('Anno', p.year),
      ('Committente', p.client),
      ('Superficie', p.area),
      ('Durata', p.duration),
      ('Stato', p.status.label),
    ].where((e) => e.$2.trim().isNotEmpty).toList();

    final story = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final para in p.description.split('\n\n'))
          if (para.trim().isNotEmpty)
            Reveal(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  para.trim(),
                  style: siteBody(context.fluid(16, 18.5)),
                ),
              ),
            ),
      ],
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in facts)
          Reveal(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      f.$1,
                      style: siteBody(14.5, color: Site.muted, height: 1.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: siteBody(
                        15.5,
                        weight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (p.works.isNotEmpty) ...[
          const SizedBox(height: 14),
          Reveal(
            child: Text(
              'Cosa abbiamo fatto',
              style: siteBody(14.5, color: Site.muted),
            ),
          ),
          const SizedBox(height: 10),
          Reveal(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in p.works)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Site.surface,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(w, style: siteBody(14, height: 1.3)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );

    return SiteScaffold(
      current: '/progetti',
      children: [
        PageHeader(
          kicker: [
            p.category,
            p.location,
          ].where((e) => e.isNotEmpty).join(' · '),
          title: p.title,
          text: p.summary,
          bottom: HoverLink(
            'Tutti i progetti',
            onTap: () => context.go('/progetti'),
            style: siteLabel(14.5, color: Site.muted),
          ),
        ),
        Section(
          top: 0,
          bottom: context.fluid(40, 70),
          child: Reveal(
            child: AspectRatio(
              aspectRatio: context.isPhone ? 4 / 3.4 : 16 / 8,
              child: Rounded(
                radius: context.isPhone ? 20 : 30,
                child: ParallaxImage(p.coverUrl, extent: 0.25),
              ),
            ),
          ),
        ),
        Section(
          top: 0,
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: story),
                    const SizedBox(width: 80),
                    Expanded(flex: 4, child: side),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [story, const SizedBox(height: 20), side],
                ),
        ),
        if (p.hasComparison)
          Section(
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  kicker: 'Prima e dopo',
                  title: 'Trascina\nper confrontare.',
                ),
                SizedBox(height: context.fluid(26, 44)),
                CompareSlider(
                  before: p.before,
                  after: p.afterUrl,
                  aspect: context.isPhone ? 4 / 3.4 : 16 / 9,
                ),
              ],
            ),
          ),
        if (p.photos.isNotEmpty)
          Section(
            top: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  kicker: 'Fotografie',
                  title: 'Il lavoro\nda vicino.',
                ),
                SizedBox(height: context.fluid(26, 44)),
                PhotoGallery(photos: p.photos),
              ],
            ),
          ),
        if (next != null) _NextProject(project: next),
      ],
    );
  }
}

/// Galleria a ritmo alternato: una foto grande, poi due affiancate. Un tocco
/// apre la foto a tutto schermo.
class PhotoGallery extends StatelessWidget {
  const PhotoGallery({super.key, required this.photos});
  final List<ProjectPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final gap = context.fluid(12, 22);
    final phone = context.isPhone;
    Widget tile(int i, double aspect) => Reveal(
      delay: Duration(milliseconds: (i % 2) * 120),
      child: _GalleryTile(
        photo: photos[i],
        aspect: aspect,
        onTap: () => openLightbox(context, photos, i),
      ),
    );

    final rows = <Widget>[];
    var i = 0;
    while (i < photos.length) {
      if (phone || i % 3 == 0 || i == photos.length - 1) {
        rows.add(tile(i, phone ? 4 / 3 : 16 / 8));
        i++;
      } else {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile(i, 4 / 3)),
              SizedBox(width: gap),
              Expanded(child: tile(i + 1, 4 / 3)),
            ],
          ),
        );
        i += 2;
      }
    }
    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: r,
          ),
      ],
    );
  }
}

class _GalleryTile extends StatefulWidget {
  const _GalleryTile({
    required this.photo,
    required this.aspect,
    required this.onTap,
  });
  final ProjectPhoto photo;
  final double aspect;
  final VoidCallback onTap;

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.zoomIn,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: widget.aspect,
            child: Rounded(
              child: AnimatedScale(
                scale: _hover ? 1.04 : 1,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                child: PhotoImage(widget.photo.url),
              ),
            ),
          ),
          if (widget.photo.caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.photo.caption,
              style: siteBody(14, color: Site.muted, height: 1.4),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Fascia finale con il progetto successivo.
class _NextProject extends StatefulWidget {
  const _NextProject({required this.project});
  final Project project;

  @override
  State<_NextProject> createState() => _NextProjectState();
}

class _NextProjectState extends State<_NextProject> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Section(
      top: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => context.go('/progetti/${p.id}'),
          child: Reveal(
            child: SizedBox(
              height: math.max(context.screenH * 0.5, 340.0),
              child: Rounded(
                radius: context.isPhone ? 20 : 30,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: _hover ? 1.05 : 1,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      child: PhotoImage(p.coverUrl, dark: true),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      color: Colors.black.withValues(
                        alpha: _hover ? 0.35 : 0.5,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(context.fluid(24, 48)),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Progetto successivo',
                              style: siteBody(15, color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              p.title,
                              textAlign: TextAlign.center,
                              style: siteHead(
                                context.fluid(40, 88),
                                color: Colors.white,
                                italic: _hover,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AnimatedSlide(
                              offset: Offset(_hover ? 0.3 : 0, 0),
                              duration: const Duration(milliseconds: 400),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
