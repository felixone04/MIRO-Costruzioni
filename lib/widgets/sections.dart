import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import 'common.dart';
import 'site_scaffold.dart';

// ====================================================================== HERO

/// Prima schermata: le copertine dei progetti in evidenza si alternano con
/// dissolvenza e zoom lento; scorrendo la foto rallenta e il testo sfuma.
class HomeHero extends StatefulWidget {
  const HomeHero({super.key});

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero> {
  static const _slide = Duration(seconds: 7);
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(_slide, (_) {
      if (mounted) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final slides = s.heroProjects;
    final h = context.screenH;
    final scroll = SiteScroll.of(context);
    final current = slides.isEmpty ? null : slides[_i % slides.length];

    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 1400),
      layoutBuilder: (cur, prev) =>
          Stack(fit: StackFit.expand, children: [...prev, ?cur]),
      child: current == null
          ? const SizedBox.expand(key: ValueKey('none'))
          : _KenBurns(
              key: ValueKey('${current.id}-$_i'),
              url: current.coverUrl,
            ),
    );

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: Kicker(c.heroKicker, dark: true)),
        SizedBox(height: context.fluid(18, 26)),
        RevealTitle(
          c.heroTitle,
          delay: const Duration(milliseconds: 100),
          style: siteHead(
            context.fluid(54, 132),
            color: Colors.white,
            height: 0.98,
          ),
          // Sulla foto scura l'accento va schiarito per restare leggibile.
          accentColor: Color.lerp(Site.accent, Colors.white, 0.35),
        ),
        SizedBox(height: context.fluid(18, 26)),
        Reveal(
          delay: const Duration(milliseconds: 450),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              c.heroSubtitle,
              style: siteBody(
                context.fluid(16, 18.5),
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        SizedBox(height: context.fluid(26, 36)),
        Reveal(
          delay: const Duration(milliseconds: 600),
          child: SiteButton(
            'Guarda i progetti',
            big: true,
            onTap: () => context.go('/progetti'),
          ),
        ),
      ],
    );

    final info = current == null
        ? const SizedBox.shrink()
        : _HeroInfo(
            project: current,
            index: _i % slides.length,
            count: slides.length,
            duration: _slide,
            onJump: (i) {
              setState(() => _i = i);
              _start();
            },
          );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        text,
        SizedBox(height: context.fluid(30, 48)),
        info,
      ],
    );

    // Alta quanto lo schermo; se il testo non ci sta (telefoni piccoli) la
    // sezione si allunga invece di tagliarlo. Gli angoli in basso sono
    // arrotondati, come una grande fotografia appoggiata sulla pagina.
    final radius = context.isPhone ? 22.0 : 34.0;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: Site.night)),
          Positioned.fill(
            child: scroll == null
                ? image
                : AnimatedBuilder(
                    animation: scroll,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        scroll.hasClients ? scroll.offset.clamp(0, h) * 0.4 : 0,
                      ),
                      child: child,
                    ),
                    child: image,
                  ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.45, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: h, minWidth: context.w),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.gutter,
                context.navH + 20,
                context.gutter,
                // Spazio per il pulsante "Colori" in basso a sinistra.
                context.fluid(28, 44) + (s.switcherVisible ? 64 : 0),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: scroll == null
                      ? content
                      : AnimatedBuilder(
                          animation: scroll,
                          builder: (context, child) {
                            final o = scroll.hasClients ? scroll.offset : 0.0;
                            return Opacity(
                              opacity: (1 - o / (h * 0.7)).clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, -o * 0.15),
                                child: child,
                              ),
                            );
                          },
                          child: content,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KenBurns extends StatelessWidget {
  const _KenBurns({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 1.0, end: 1.12),
    duration: const Duration(seconds: 9),
    curve: Curves.easeOut,
    builder: (context, s, child) => Transform.scale(scale: s, child: child),
    child: PhotoImage(url, dark: true),
  );
}

/// In fondo alla prima schermata: il progetto mostrato e l'avanzamento.
class _HeroInfo extends StatelessWidget {
  const _HeroInfo({
    required this.project,
    required this.index,
    required this.count,
    required this.duration,
    required this.onJump,
  });
  final Project project;
  final int index;
  final int count;
  final Duration duration;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final wide = context.w >= 760;
    final label = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/progetti/${project.id}'),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          layoutBuilder: (cur, prev) =>
              Stack(alignment: Alignment.centerLeft, children: [...prev, ?cur]),
          child: Row(
            key: ValueKey(project.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: siteHead(18, color: Colors.white, italic: true),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  project.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: siteBody(14, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onJump(i),
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 3,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: i == index ? (wide ? 46 : 32) : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  child: i == index
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey('bar-$index'),
                          tween: Tween(begin: 0, end: 1),
                          duration: duration,
                          builder: (context, t, _) => FractionallySizedBox(
                            widthFactor: t,
                            heightFactor: 1,
                            child: ColoredBox(color: Site.accent),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
    return Reveal(
      delay: const Duration(milliseconds: 700),
      child: wide
          ? Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: label),
                ),
                dots,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 6), dots],
            ),
    );
  }
}

// ===================================================================== INTRO

/// Chi siamo in poche righe e i numeri dell'impresa.
class IntroSection extends StatelessWidget {
  const IntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 980;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Reveal(child: Kicker(c.introKicker)),
        SizedBox(height: context.fluid(14, 22)),
        RevealTitle(c.introTitle, style: siteHead(context.fluid(36, 64))),
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 200),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              c.introText,
              style: siteBody(context.fluid(16, 17.5), color: Site.muted),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Reveal(
          delay: const Duration(milliseconds: 300),
          child: HoverLink(
            'La nostra storia',
            arrow: true,
            onTap: () => context.go('/azienda'),
            style: siteLabel(15, color: Site.accentDeep),
          ),
        ),
      ],
    );
    final stats = Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (var i = 0; i < c.stats.length; i++)
          Reveal(
            delay: Duration(milliseconds: 120 * i),
            child: Container(
              width: wide ? 200 : (context.w - context.gutter * 2 - 14) / 2,
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 22),
              decoration: BoxDecoration(
                color: Site.surface,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CountUp(
                    c.stats[i].title,
                    style: siteHead(
                      context.fluid(40, 54),
                      color: Site.accent,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.stats[i].text,
                    style: siteBody(14, color: Site.muted, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
    return Section(
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: text),
                const SizedBox(width: 60),
                SizedBox(width: 414, child: stats),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 36), stats],
            ),
    );
  }
}

// ==================================================================== TICKER

/// Nastro che scorre all'infinito con i servizi, alternando parole dritte e
/// in corsivo.
class Ticker extends StatefulWidget {
  const Ticker({super.key});

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 45),
  )..repeat();
  final _first = GlobalKey();
  double _w = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _measure() {
    final box = _first.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize && box.size.width != _w) {
      setState(() => _w = box.size.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<AppState>().content.ticker;
    if (items.isEmpty) return const SizedBox.shrink();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final size = context.fluid(34, 64);
    Widget set([Key? key]) => Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Text(
            items[i],
            style: siteHead(
              size,
              italic: i.isOdd,
              color: i.isOdd ? Site.accent : Site.ink,
              height: 1.2,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.5),
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Site.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.fluid(10, 24)),
      child: ClipRect(
        child: SizedBox(
          height: size * 1.4,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(-_c.value * _w, 0),
                child: child,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [set(_first), set(), set(), set()],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================== PROGETTI

/// Scheda di un progetto: foto arrotondata che si avvicina al passaggio del
/// mouse, titolo e luogo.
class ProjectCard extends StatefulWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.aspect = 4 / 3,
    this.showSummary = false,
  });
  final Project project;
  final double aspect;
  final bool showSummary;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final meta = [
      p.location,
      p.year,
    ].where((e) => e.trim().isNotEmpty).join(' · ');
    return Semantics(
      button: true,
      label: 'Progetto ${p.title}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: () => context.go('/progetti/${p.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: widget.aspect,
                child: Rounded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hover ? 1.06 : 1,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        child: PhotoImage(p.coverUrl),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (p.category.isNotEmpty)
                              _Pill(
                                p.category,
                                color: Colors.white.withValues(alpha: 0.92),
                                onColor: const Color(0xFF222222),
                              ),
                            if (p.status == ProjectStatus.inCorso)
                              _Pill(
                                'In corso',
                                color: Site.accent,
                                onColor: Site.onAccent,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: AnimatedScale(
                          scale: _hover ? 1 : 0.6,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: _hover ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Site.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                color: Site.onAccent,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: siteHead(
                  context.fluid(24, 30),
                  color: _hover ? Site.accent : Site.ink,
                  italic: _hover,
                ),
                child: Text(p.title),
              ),
              const SizedBox(height: 4),
              Text(meta, style: siteBody(14, color: Site.muted, height: 1.4)),
              if (widget.showSummary && p.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(p.summary, style: siteBody(15, color: Site.muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.color, required this.onColor});
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(text, style: siteLabel(12, color: onColor, height: 1.2)),
  );
}

/// Griglia di progetti: 1, 2 o 3 colonne secondo lo schermo.
class ProjectGrid extends StatelessWidget {
  const ProjectGrid({
    super.key,
    required this.projects,
    this.showSummary = false,
  });
  final List<Project> projects;
  final bool showSummary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1000 ? 3 : (box.maxWidth >= 600 ? 2 : 1);
        final gap = context.fluid(18, 34);
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap * 1.6,
          children: [
            for (var i = 0; i < projects.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  delay: Duration(milliseconds: 100 * (i % cols)),
                  child: ProjectCard(
                    project: projects[i],
                    showSummary: showSummary,
                    aspect: cols == 1 ? 4 / 3.4 : 4 / 3.2,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Gli ultimi progetti in evidenza, con il link a tutti.
class RecentProjects extends StatelessWidget {
  const RecentProjects({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    // Righe sempre piene: 3 su tre colonne, 4 su due, 3 su una.
    final n = context.w >= 1000 ? 3 : (context.w >= 600 ? 4 : 3);
    final list = s.featuredProjects.take(n).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            kicker: c.projectsKicker,
            title: c.projectsTitle,
            text: c.projectsText,
            trailing: SiteButton(
              'Tutti i progetti',
              kind: ButtonKind.outline,
              onTap: () => context.go('/progetti'),
            ),
          ),
          SizedBox(height: context.fluid(36, 64)),
          ProjectGrid(projects: list),
        ],
      ),
    );
  }
}

// ================================================================== RECAPITI

/// Chiusura della Home: dove siamo e come raggiungerci, senza fronzoli.
class ContactStrip extends StatelessWidget {
  const ContactStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final k = c.contacts;
    final items = [
      if (k.phone.isNotEmpty)
        (
          Icons.call_outlined,
          'Telefono',
          k.phone,
          'tel:${phoneDigits(k.phone)}',
        ),
      if (k.email.isNotEmpty)
        (Icons.mail_outline_rounded, 'Email', k.email, 'mailto:${k.email}'),
      if (k.address.isNotEmpty)
        (Icons.place_outlined, 'Sede', k.address, mapsUrl(k.address)),
    ];
    return Section(
      top: 0,
      child: Reveal(
        child: Container(
          padding: EdgeInsets.all(context.fluid(26, 56)),
          decoration: BoxDecoration(
            color: Site.concrete,
            borderRadius: BorderRadius.circular(context.isPhone ? 22 : 30),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 860;
              final title = RevealTitle(
                'Parliamo del\ntuo progetto.',
                style: siteHead(context.fluid(34, 56)),
              );
              final list = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final it in items)
                    _ContactLine(
                      icon: it.$1,
                      label: it.$2,
                      value: it.$3,
                      url: it.$4,
                    ),
                  const SizedBox(height: 14),
                  HoverLink(
                    'Scrivici dal modulo',
                    arrow: true,
                    onTap: () => context.go('/contatti'),
                    style: siteLabel(15, color: Site.accentDeep),
                  ),
                ],
              );
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 40),
                        Expanded(child: list),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 26), list],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _ContactLine extends StatefulWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
  });
  final IconData icon;
  final String label;
  final String value;
  final String url;

  @override
  State<_ContactLine> createState() => _ContactLineState();
}

class _ContactLineState extends State<_ContactLine> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: () => openUrl(widget.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hover ? Site.accent : Site.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 19,
                color: _hover ? Site.onAccent : Site.ink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: siteBody(12.5, color: Site.muted, height: 1.3),
                  ),
                  Text(
                    widget.value,
                    style: siteBody(16, weight: FontWeight.w500, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
