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
  ProjectStatus? _status;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final all = s.publishedProjects;
    final cats = s.usedCategories;
    final category = cats.contains(_category) ? _category : null;
    final list = all
        .where((p) => category == null || p.category == category)
        .where((p) => _status == null || p.status == _status)
        .toList();
    final inProgress = all
        .where((p) => p.status == ProjectStatus.inCorso)
        .length;

    final filters = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Tutti',
          count: all.length,
          selected: category == null,
          onTap: () => setState(() => _category = null),
        ),
        for (final cat in cats)
          _FilterChip(
            label: cat,
            count: all.where((p) => p.category == cat).length,
            selected: category == cat,
            onTap: () => setState(() => _category = cat),
          ),
      ],
    );

    final status = Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        for (final (label, st) in [
          ('Tutti', null),
          ('Completati', ProjectStatus.completato),
          ('In corso', ProjectStatus.inCorso),
        ])
          HoverLink(
            label.toUpperCase(),
            active: _status == st,
            onTap: () => setState(() => _status = st),
            style: siteMono(
              12,
              weight: FontWeight.w600,
              color: _status == st ? Site.ink : Site.muted,
            ),
          ),
      ],
    );

    return SiteScaffold(
      current: '/progetti',
      children: [
        PageHero(
          kicker: 'Portfolio · ${all.length} progetti',
          title: c.projectsTitle,
          text: c.projectsText,
          image: all.isNotEmpty ? all.first.coverUrl : '',
          bottom: Wrap(
            spacing: 34,
            runSpacing: 14,
            children: [
              _HeroFigure('${all.length}', 'progetti'),
              _HeroFigure('${cats.length}', 'categorie'),
              if (inProgress > 0) _HeroFigure('$inProgress', 'cantieri aperti'),
            ],
          ),
        ),
        Section(
          top: context.fluid(40, 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Reveal(child: filters),
              const SizedBox(height: 22),
              Reveal(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(child: status),
                    Text(
                      '${list.length.toString().padLeft(2, '0')} RISULTATI',
                      style: siteMono(11.5, color: Site.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: Site.line),
              SizedBox(height: context.fluid(34, 60)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, a) =>
                    FadeTransition(opacity: a, child: child),
                child: KeyedSubtree(
                  key: ValueKey('$category-$_status'),
                  child: list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Text(
                              'Nessun progetto con questi filtri.',
                              style: siteBody(16, color: Site.muted),
                            ),
                          ),
                        )
                      : _Grid(projects: list),
                ),
              ),
            ],
          ),
        ),
        const CtaSection(),
      ],
    );
  }
}

class _HeroFigure extends StatelessWidget {
  const _HeroFigure(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        value,
        style: siteHead(40, color: Site.accent, weight: FontWeight.w700),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label.toUpperCase(),
          style: siteMono(11, color: Colors.white70),
        ),
      ),
    ],
  );
}

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.selected;
    return Semantics(
      button: true,
      selected: on,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: on
                  ? Site.ink
                  : (_hover ? Site.concrete : Colors.transparent),
              border: Border.all(color: on ? Site.ink : Site.line, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: siteMono(
                    12,
                    weight: FontWeight.w600,
                    color: on ? Colors.white : Site.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.count}',
                  style: siteMono(11, color: on ? Site.accent : Site.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.projects});
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1100 ? 3 : (box.maxWidth >= 640 ? 2 : 1);
        final gap = context.fluid(20, 40);
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap * 1.6,
          children: [
            for (var i = 0; i < projects.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  delay: Duration(milliseconds: 90 * (i % cols)),
                  child: ProjectCard(
                    project: projects[i],
                    number: i + 1,
                    aspect: cols == 1 ? 4 / 3.6 : 4 / 3,
                  ),
                ),
              ),
          ],
        );
      },
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
          PageHero(
            kicker: 'Progetto non trovato',
            title: 'Questo cantiere\nnon esiste.',
            image: s.content.ctaImage,
            bottom: SiteButton(
              'Tutti i progetti',
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

    return SiteScaffold(
      current: '/progetti',
      children: [
        PageHero(
          kicker: [
            p.category,
            p.location,
          ].where((e) => e.isNotEmpty).join(' · '),
          title: p.title,
          text: p.summary,
          image: p.coverUrl,
          height: context.screenH,
          bottom: HoverLink(
            '← TUTTI I PROGETTI',
            onTap: () => context.go('/progetti'),
            style: siteMono(12, color: Colors.white, weight: FontWeight.w600),
          ),
        ),
        // Scheda tecnica.
        Container(
          color: Site.night,
          padding: EdgeInsets.symmetric(horizontal: context.gutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: LayoutBuilder(
                builder: (context, box) {
                  final cols = box.maxWidth >= 1100
                      ? math.max(facts.length, 1)
                      : (box.maxWidth >= 600 ? 3 : 2);
                  // Righe con celle di pari altezza (bordi allineati).
                  return Column(
                    children: [
                      for (var r = 0; r < facts.length; r += cols)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = r; i < r + cols; i++)
                                Expanded(
                                  child: i >= facts.length
                                      ? const SizedBox()
                                      : Reveal(
                                          delay: Duration(milliseconds: 80 * i),
                                          child: Container(
                                            padding: EdgeInsets.fromLTRB(
                                              i % cols == 0 ? 0 : 18,
                                              28,
                                              12,
                                              28,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: i % cols == 0
                                                    ? BorderSide.none
                                                    : const BorderSide(
                                                        color: Site.lineDark,
                                                      ),
                                                bottom: const BorderSide(
                                                  color: Site.lineDark,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  facts[i].$1.toUpperCase(),
                                                  style: siteMono(
                                                    11,
                                                    color: Site.accent,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  facts[i].$2.toUpperCase(),
                                                  style: siteHead(
                                                    context.fluid(22, 28),
                                                    color: Colors.white,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // Racconto e interventi.
        Section(
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _flex(
                wide,
                7,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Reveal(child: Tag('Il progetto', number: '01')),
                    const SizedBox(height: 26),
                    for (final para in p.description.split('\n\n'))
                      if (para.trim().isNotEmpty)
                        Reveal(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              para.trim(),
                              style: siteBody(context.fluid(16, 19)),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              SizedBox(width: wide ? 80 : 0, height: wide ? 0 : 30),
              if (p.works.isNotEmpty)
                _flex(
                  wide,
                  5,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Reveal(
                        child: Tag('Interventi eseguiti', number: '02'),
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < p.works.length; i++)
                        Reveal(
                          delay: Duration(milliseconds: 70 * i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Site.line),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  (i + 1).toString().padLeft(2, '0'),
                                  style: siteMono(12, color: Site.accentDeep),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    p.works[i].toUpperCase(),
                                    style: siteHead(context.fluid(22, 26)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (p.hasComparison)
          Section(
            color: Site.concrete,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  kicker: 'Prima e dopo',
                  number: '03',
                  title: 'Trascina\nper confrontare.',
                ),
                SizedBox(height: context.fluid(30, 56)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  kicker: 'Galleria · ${p.photos.length} foto',
                  number: p.hasComparison ? '04' : '03',
                  title: 'Il cantiere\nin immagini.',
                ),
                SizedBox(height: context.fluid(30, 56)),
                _Gallery(photos: p.photos),
              ],
            ),
          ),
        // Invito.
        Section(
          color: Site.accent,
          top: context.fluid(56, 90),
          bottom: context.fluid(56, 90),
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              _flex(
                wide,
                1,
                RevealTitle(
                  'Vuoi realizzare\nqualcosa di simile?',
                  style: siteHead(context.fluid(40, 72), color: Site.onAccent),
                ),
              ),
              SizedBox(width: 30, height: wide ? 0 : 26),
              Reveal(
                child: SiteButton(
                  'Parliamone',
                  big: true,
                  // Sull'accento chiaro bottone scuro, su quello scuro chiaro.
                  kind: Site.onAccent.computeLuminance() > 0.5
                      ? ButtonKind.light
                      : ButtonKind.dark,
                  onTap: () => context.go(
                    Uri(
                      path: '/contatti',
                      queryParameters: {
                        'progetto': p.title,
                        if (p.category.isNotEmpty) 'categoria': p.category,
                      },
                    ).toString(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (next != null) _NextProject(project: next),
      ],
    );
  }

  static Widget _flex(bool wide, int flex, Widget child) =>
      wide ? Expanded(flex: flex, child: child) : child;
}

/// Galleria a ritmo alternato: una foto grande, poi due affiancate.
class _Gallery extends StatelessWidget {
  const _Gallery({required this.photos});
  final List<ProjectPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final gap = context.fluid(12, 24);
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
            child: ClipRect(
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
              widget.photo.caption.toUpperCase(),
              style: siteMono(11, color: Site.muted),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.go('/progetti/${p.id}'),
        child: SizedBox(
          height: math.max(context.screenH * 0.6, 420.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Site.night,
                child: AnimatedScale(
                  scale: _hover ? 1.05 : 1,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  child: PhotoImage(p.coverUrl, dark: true),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                color: Site.night.withValues(alpha: _hover ? 0.5 : 0.7),
              ),
              Padding(
                padding: EdgeInsets.all(context.gutter),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PROGETTO SUCCESSIVO',
                        style: siteMono(12, color: Site.accent),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        p.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: siteHead(
                          context.fluid(48, 120),
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSlide(
                        offset: Offset(_hover ? 0.3 : 0, 0),
                        duration: const Duration(milliseconds: 400),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 34,
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
    );
  }
}
