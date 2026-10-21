import 'dart:async';
import 'dart:math' as math;

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
    _timer = Timer.periodic(_slide, (_) {
      if (mounted) setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _jump(int i) {
    _timer?.cancel();
    setState(() => _i = i);
    _timer = Timer.periodic(_slide, (_) {
      if (mounted) setState(() => _i++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final slides = s.heroProjects;
    final h = context.screenH;
    final scroll = SiteScroll.of(context);
    final current = slides.isEmpty ? null : slides[_i % slides.length];
    final wide = context.w >= 900;

    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 1400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
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
        Reveal(child: Tag(c.heroKicker, number: '01', dark: true)),
        SizedBox(height: context.fluid(20, 30)),
        RevealTitle(
          c.heroTitle,
          delay: const Duration(milliseconds: 100),
          style: siteHead(
            context.fluid(68, 178),
            color: Colors.white,
            weight: FontWeight.w700,
            height: 0.88,
            spacing: -1,
          ),
          accentLast: true,
        ),
        SizedBox(height: context.fluid(20, 30)),
        Reveal(
          delay: const Duration(milliseconds: 450),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              c.heroSubtitle,
              style: siteBody(
                context.fluid(15.5, 18.5),
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ),
        ),
        SizedBox(height: context.fluid(26, 40)),
        Reveal(
          delay: const Duration(milliseconds: 600),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SiteButton(
                'Scopri i progetti',
                big: true,
                onTap: () => context.go('/progetti'),
              ),
              SiteButton(
                'Contattaci',
                big: true,
                kind: ButtonKind.light,
                onTap: () => context.go('/contatti'),
              ),
            ],
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
            onJump: _jump,
          );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        text,
        SizedBox(height: context.fluid(24, 40)),
        info,
      ],
    );

    // Alta quanto lo schermo; se il testo non ci sta (telefoni piccoli) la
    // sezione si allunga invece di tagliarlo.
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: Site.night)),
          // La foto scorre più lentamente della pagina.
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
                    Site.night.withValues(alpha: 0.30),
                    Site.night.withValues(alpha: 0.20),
                    Site.night.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Site.night.withValues(alpha: 0.55),
                    Site.night.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: BlueprintGrid()),
          // Riferimenti "da tavola" nell'angolo.
          if (wide)
            Positioned(
              right: context.gutter,
              top: context.navH + 26,
              child: Reveal(
                delay: const Duration(milliseconds: 800),
                child: Text(
                  '41.1171° N\n16.8719° E',
                  textAlign: TextAlign.right,
                  style: siteMono(11, color: Colors.white54),
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
                context.fluid(28, 48) + (s.switcherVisible ? 64 : 0),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
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
    final label = Reveal(
      delay: const Duration(milliseconds: 700),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go('/progetti/${project.id}'),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            layoutBuilder: (cur, prev) => Stack(
              alignment: Alignment.centerLeft,
              children: [...prev, ?cur],
            ),
            child: Row(
              key: ValueKey(project.id),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(index + 1).toString().padLeft(2, '0')}/${count.toString().padLeft(2, '0')}',
                  style: siteMono(12, color: Site.accent),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    '${project.title.toUpperCase()}  ·  ${project.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: siteMono(12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final bars = Row(
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
                child: SizedBox(
                  width: wide ? 54 : 34,
                  height: 2,
                  child: Stack(
                    children: [
                      Container(color: Colors.white24),
                      if (i < index) Container(color: Colors.white),
                      if (i == index)
                        TweenAnimationBuilder<double>(
                          key: ValueKey('bar-$index'),
                          tween: Tween(begin: 0, end: 1),
                          duration: duration,
                          builder: (context, t, _) => FractionallySizedBox(
                            widthFactor: t,
                            child: Container(color: Site.accent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: Colors.white24),
        const SizedBox(height: 14),
        if (wide)
          Row(
            children: [
              const _ScrollCue(),
              const SizedBox(width: 30),
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: label),
              ),
              bars,
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, const SizedBox(height: 4), bars],
          ),
      ],
    );
  }
}

/// "Scorri" con una lineetta che scende all'infinito.
class _ScrollCue extends StatefulWidget {
  const _ScrollCue();

  @override
  State<_ScrollCue> createState() => _ScrollCueState();
}

class _ScrollCueState extends State<_ScrollCue>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 1.5,
        height: 26,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Align(
              alignment: Alignment(0, -1.6 + _c.value * 3.2),
              child: Container(width: 1.5, height: 12, color: Site.accent),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text('SCORRI', style: siteMono(11.5, color: Colors.white70)),
    ],
  );
}

// ===================================================================== INTRO

class IntroSection extends StatelessWidget {
  const IntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 980;
    final stats = LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 860 ? 4 : 2;
        final w = box.maxWidth / cols;
        return Wrap(
          children: [
            for (var i = 0; i < c.stats.length; i++)
              SizedBox(
                width: w,
                child: Reveal(
                  delay: Duration(milliseconds: 120 * i),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      i % cols == 0 ? 0 : 20,
                      26,
                      16,
                      26,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Site.line),
                        left: i % cols == 0
                            ? BorderSide.none
                            : BorderSide(color: Site.line),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CountUp(
                          c.stats[i].title,
                          style: siteHead(
                            context.fluid(56, 104),
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.stats[i].text.toUpperCase(),
                          style: siteMono(11.5, color: Site.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
    return Section(
      color: Site.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Reveal(child: Tag(c.introKicker, number: '02')),
                ),
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RevealTitle(
                        c.introTitle,
                        style: siteHead(context.fluid(44, 84)),
                        accentLast: true,
                      ),
                      const SizedBox(height: 30),
                      Reveal(
                        delay: const Duration(milliseconds: 200),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Text(
                            c.introText,
                            style: siteBody(17.5, color: Site.muted),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Reveal(
                        delay: const Duration(milliseconds: 300),
                        child: HoverLink(
                          'LA NOSTRA STORIA',
                          arrow: true,
                          onTap: () => context.go('/azienda'),
                          style: siteMono(13, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            Reveal(child: Tag(c.introKicker, number: '02')),
            const SizedBox(height: 20),
            RevealTitle(
              c.introTitle,
              style: siteHead(context.fluid(42, 84)),
              accentLast: true,
            ),
            const SizedBox(height: 22),
            Reveal(
              child: Text(c.introText, style: siteBody(16, color: Site.muted)),
            ),
            const SizedBox(height: 22),
            Reveal(
              child: HoverLink(
                'LA NOSTRA STORIA',
                arrow: true,
                onTap: () => context.go('/azienda'),
                style: siteMono(13, weight: FontWeight.w600),
              ),
            ),
          ],
          SizedBox(height: context.fluid(56, 100)),
          stats,
        ],
      ),
    );
  }
}

// ==================================================================== TICKER

/// Nastro che scorre all'infinito con i servizi, alternando parole piene e
/// parole a contorno.
class Ticker extends StatefulWidget {
  const Ticker({super.key, this.dark = false});
  final bool dark;

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
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
    final size = context.fluid(38, 76);
    final fg = widget.dark ? Colors.white : Site.ink;
    Widget set([Key? key]) => Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Text(
            items[i].toUpperCase(),
            style: i.isEven
                ? siteHead(size, color: fg, weight: FontWeight.w700)
                : siteOutline(size, color: fg),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.5),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: size * 0.18,
                height: size * 0.18,
                color: Site.accent,
              ),
            ),
          ),
        ],
      ],
    );
    return Container(
      color: widget.dark ? Site.night : Site.concrete,
      padding: EdgeInsets.symmetric(vertical: context.fluid(18, 30)),
      child: ClipRect(
        child: SizedBox(
          height: size * 1.1,
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

/// Scheda di un progetto: foto che si avvicina al passaggio del mouse,
/// categoria, stato, titolo e dati essenziali.
class ProjectCard extends StatefulWidget {
  const ProjectCard({
    super.key,
    required this.project,
    this.aspect = 4 / 3,
    this.number,
    this.big = false,
  });
  final Project project;
  final double aspect;
  final int? number;
  final bool big;

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
    ].where((e) => e.trim().isNotEmpty).join('  ·  ');
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
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hover ? 1.07 : 1,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        child: PhotoImage(p.coverUrl),
                      ),
                      AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Site.night.withValues(alpha: 0.05),
                                Site.night.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 14,
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (p.category.isNotEmpty)
                              _Badge(
                                p.category,
                                color: Colors.white,
                                onColor: Site.ink,
                              ),
                            if (p.status == ProjectStatus.inCorso)
                              _Badge(
                                'In corso',
                                color: Site.accent,
                                onColor: Site.onAccent,
                              ),
                          ],
                        ),
                      ),
                      // "Apri" che entra dal basso al passaggio del mouse.
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: AnimatedSlide(
                          offset: Offset(0, _hover ? 0 : 0.4),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: _hover ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: 54,
                              height: 54,
                              color: Site.accent,
                              child: Icon(
                                Icons.arrow_outward_rounded,
                                color: Site.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.number != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.number!.toString().padLeft(2, '0'),
                        style: siteMono(12, color: Site.accentDeep),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: siteHead(
                            widget.big
                                ? context.fluid(30, 44)
                                : context.fluid(26, 34),
                            color: _hover ? Site.accentDeep : Site.ink,
                          ),
                          child: Text(p.title.toUpperCase()),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          meta.toUpperCase(),
                          style: siteMono(11.5, color: Site.muted),
                        ),
                        if (widget.big && p.summary.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            p.summary,
                            style: siteBody(15, color: Site.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.color, required this.onColor});
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    color: color,
    child: Text(
      text.toUpperCase(),
      style: siteMono(10.5, color: onColor, weight: FontWeight.w600),
    ),
  );
}

/// Progetti in evidenza: impaginazione "a rivista", schede sfalsate.
class FeaturedProjects extends StatelessWidget {
  const FeaturedProjects({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final list = s.featuredProjects.take(6).toList();
    final wide = context.w >= 900;
    final gap = context.fluid(24, 56);

    final rows = <Widget>[];
    if (wide) {
      for (var i = 0; i < list.length; i += 2) {
        final a = ProjectCard(
          project: list[i],
          number: i + 1,
          aspect: 4 / 3,
          big: true,
        );
        final b = i + 1 < list.length
            ? ProjectCard(project: list[i + 1], number: i + 2, aspect: 4 / 5)
            : null;
        final left = (i ~/ 2).isEven;
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: gap * 1.6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: left ? 7 : 5,
                  child: Padding(
                    padding: EdgeInsets.only(top: left ? 0 : gap * 2.4),
                    child: Reveal(child: left ? a : (b ?? const SizedBox())),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  flex: left ? 5 : 7,
                  child: Padding(
                    padding: EdgeInsets.only(top: left ? gap * 2.4 : 0),
                    child: Reveal(
                      delay: const Duration(milliseconds: 150),
                      child: left ? (b ?? const SizedBox()) : a,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      for (var i = 0; i < list.length; i++) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: gap * 1.6),
            child: Reveal(
              child: ProjectCard(
                project: list[i],
                number: i + 1,
                aspect: context.isPhone ? 4 / 4.2 : 16 / 11,
                big: true,
              ),
            ),
          ),
        );
      }
    }

    return Section(
      color: Site.paper,
      top: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.fluid(72, 140)),
          SectionHeading(
            kicker: c.projectsKicker,
            number: '03',
            title: c.projectsTitle,
            text: c.projectsText,
            trailing: SiteButton(
              'Tutti i progetti',
              kind: ButtonKind.dark,
              onTap: () => context.go('/progetti'),
            ),
          ),
          SizedBox(height: context.fluid(48, 90)),
          ...rows,
        ],
      ),
    );
  }
}

// ==================================================================== SERVIZI

/// Servizi su fondo scuro: elenco numerato che si apre al passaggio del
/// mouse (o al tocco) con la foto del servizio accanto.
class ServicesSection extends StatefulWidget {
  const ServicesSection({super.key, this.showHeading = true});
  final bool showHeading;

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection> {
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    final list = s.activeServices;
    if (list.isEmpty) return const SizedBox.shrink();
    final open = _open.clamp(0, list.length - 1);
    final wide = context.w >= 1000;

    final rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < list.length; i++)
          Reveal(
            delay: Duration(milliseconds: 70 * i),
            child: _ServiceRow(
              service: list[i],
              number: i + 1,
              open: i == open,
              showImage: !wide,
              onHover: wide ? () => setState(() => _open = i) : null,
              onTap: () => setState(() => _open = i),
            ),
          ),
        Container(height: 1, color: Site.lineDark),
      ],
    );

    final image = AspectRatio(
      aspectRatio: 4 / 5,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        layoutBuilder: (cur, prev) =>
            Stack(fit: StackFit.expand, children: [...prev, ?cur]),
        child: Stack(
          key: ValueKey(list[open].id),
          fit: StackFit.expand,
          children: [
            PhotoImage(list[open].image, dark: true),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                color: Site.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  '${(open + 1).toString().padLeft(2, '0')} — ${list[open].title.toUpperCase()}',
                  style: siteMono(
                    11.5,
                    color: Site.onAccent,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Section(
      color: Site.night,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeading) ...[
            SectionHeading(
              kicker: c.servicesKicker,
              number: '04',
              title: c.servicesTitle,
              text: c.servicesText,
              dark: true,
            ),
            SizedBox(height: context.fluid(44, 80)),
          ],
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: rows),
                const SizedBox(width: 64),
                Expanded(flex: 4, child: Reveal(child: image)),
              ],
            )
          else
            rows,
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.number,
    required this.open,
    required this.showImage,
    required this.onTap,
    this.onHover,
  });
  final ServiceItem service;
  final int number;
  final bool open;
  final bool showImage;
  final VoidCallback onTap;
  final VoidCallback? onHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: onHover == null ? null : (_) => onHover!(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Site.lineDark)),
          ),
          padding: EdgeInsets.symmetric(vertical: context.fluid(20, 28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: context.fluid(44, 70),
                    child: Text(
                      number.toString().padLeft(2, '0'),
                      style: siteMono(13, color: Site.accent),
                    ),
                  ),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: siteHead(
                        context.fluid(28, 52),
                        color: open ? Colors.white : Colors.white54,
                      ),
                      child: Text(service.title.toUpperCase()),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.125 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.add_rounded,
                      size: 28,
                      color: open ? Site.accent : Colors.white54,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topLeft,
                child: !open
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: EdgeInsets.only(
                          left: context.fluid(44, 70),
                          top: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Text(
                                service.text,
                                style: siteBody(16, color: Site.mutedDark),
                              ),
                            ),
                            if (service.points.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final p in service.points)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
                                      ),
                                      child: Text(
                                        p.toUpperCase(),
                                        style: siteMono(
                                          10.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (showImage && service.image.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              AspectRatio(
                                aspectRatio: 16 / 10,
                                child: PhotoImage(service.image, dark: true),
                              ),
                            ],
                            const SizedBox(height: 18),
                            HoverLink(
                              'RICHIEDI UN SOPRALLUOGO',
                              arrow: true,
                              onTap: () => context.go(
                                Uri(
                                  path: '/contatti',
                                  queryParameters: {'tipo': service.title},
                                ).toString(),
                              ),
                              style: siteMono(
                                12.5,
                                color: Site.accent,
                                weight: FontWeight.w600,
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

// ===================================================================== METODO

/// Le fasi di lavoro con una linea che si "costruisce" mentre compare.
class ProcessSection extends StatelessWidget {
  const ProcessSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    if (c.process.isEmpty) return const SizedBox.shrink();
    final wide = context.w >= 900;

    Widget step(Milestone m, int i) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(m.year, style: siteOutline(context.fluid(64, 110), stroke: 1.3)),
        const SizedBox(height: 14),
        Text(m.title.toUpperCase(), style: siteHead(context.fluid(26, 32))),
        const SizedBox(height: 10),
        Text(m.text, style: siteBody(15, color: Site.muted)),
      ],
    );

    return Section(
      color: Site.concrete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            kicker: c.processKicker,
            number: '05',
            title: c.processTitle,
          ),
          SizedBox(height: context.fluid(44, 80)),
          if (wide) ...[
            const _BuildLine(),
            const SizedBox(height: 34),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < c.process.length; i++) ...[
                  if (i > 0) const SizedBox(width: 36),
                  Expanded(
                    child: Reveal(
                      delay: Duration(milliseconds: 200 * i),
                      child: step(c.process[i], i),
                    ),
                  ),
                ],
              ],
            ),
          ] else
            for (var i = 0; i < c.process.length; i++)
              Reveal(
                child: Container(
                  padding: const EdgeInsets.only(left: 22, bottom: 34),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Site.accent, width: 2),
                    ),
                  ),
                  child: step(c.process[i], i),
                ),
              ),
        ],
      ),
    );
  }
}

/// Linea orizzontale che si riempie da sinistra quando diventa visibile.
class _BuildLine extends StatelessWidget {
  const _BuildLine();

  @override
  Widget build(BuildContext context) => Reveal(
    offset: 0,
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2400),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) => Stack(
        children: [
          Container(height: 2, color: Site.line),
          FractionallySizedBox(
            widthFactor: t,
            child: Container(height: 2, color: Site.accent),
          ),
        ],
      ),
    ),
  );
}

// ================================================================= CITAZIONE

class QuoteBand extends StatelessWidget {
  const QuoteBand({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    if (c.quoteText.trim().isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: math.max(context.screenH * 0.8, 520.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Site.night,
            child: ParallaxImage(c.quoteImage, extent: 0.35, dark: true),
          ),
          ColoredBox(color: Site.night.withValues(alpha: 0.62)),
          const BlueprintGrid(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.gutter),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Reveal(
                      child: Text(
                        '“',
                        style: siteHead(
                          context.fluid(90, 160),
                          color: Site.accent,
                          height: 0.6,
                        ),
                      ),
                    ),
                    Reveal(
                      delay: const Duration(milliseconds: 150),
                      child: Text(
                        c.quoteText.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: siteHead(
                          context.fluid(30, 62),
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Reveal(
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        '— ${c.quoteAuthor.toUpperCase()}',
                        textAlign: TextAlign.center,
                        style: siteMono(12.5, color: Site.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================= TESTIMONIANZE

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
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
    final list = context.watch<AppState>().publishedTestimonials;
    if (list.isEmpty) return const SizedBox.shrink();
    final i = _i % list.length;
    final t = list[i];
    final wide = context.w >= 900;

    final quote = AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      layoutBuilder: (cur, prev) =>
          Stack(alignment: Alignment.topLeft, children: [...prev, ?cur]),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(t.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“${t.text}”',
            style: siteBody(
              context.fluid(20, 30),
              weight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          Text(t.name.toUpperCase(), style: siteHead(24)),
          if (t.role.isNotEmpty)
            Text(
              t.role.toUpperCase(),
              style: siteMono(11.5, color: Site.accentDeep),
            ),
        ],
      ),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SquareButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            setState(() => _i = (_i - 1) < 0 ? list.length - 1 : _i - 1);
            _restart();
          },
        ),
        const SizedBox(width: 10),
        _SquareButton(
          icon: Icons.arrow_forward_rounded,
          onTap: () {
            setState(() => _i++);
            _restart();
          },
        ),
        const SizedBox(width: 18),
        Text(
          '${(i + 1).toString().padLeft(2, '0')} / ${list.length.toString().padLeft(2, '0')}',
          style: siteMono(12.5),
        ),
      ],
    );

    return Section(
      color: Site.paper,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Reveal(child: Tag('Dicono di noi', number: '06')),
                      const SizedBox(height: 26),
                      RevealTitle(
                        'La parola\nai clienti.',
                        style: siteHead(context.fluid(44, 80)),
                        accentLast: true,
                      ),
                      const SizedBox(height: 36),
                      controls,
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  flex: 7,
                  child: Reveal(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 300),
                      child: quote,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Reveal(child: Tag('Dicono di noi', number: '06')),
                const SizedBox(height: 20),
                RevealTitle(
                  'La parola\nai clienti.',
                  style: siteHead(context.fluid(42, 80)),
                  accentLast: true,
                ),
                const SizedBox(height: 28),
                Reveal(child: quote),
                const SizedBox(height: 28),
                controls,
              ],
            ),
    );
  }
}

class _SquareButton extends StatefulWidget {
  const _SquareButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SquareButton> createState() => _SquareButtonState();
}

class _SquareButtonState extends State<_SquareButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _hover ? Site.ink : Colors.transparent,
          border: Border.all(color: Site.ink, width: 1.4),
        ),
        child: Icon(
          widget.icon,
          size: 20,
          color: _hover ? Colors.white : Site.ink,
        ),
      ),
    ),
  );
}

// ======================================================================= CTA

/// Invito finale: testo su fondo scuro accanto a una foto di cantiere.
class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 900;
    final phone = c.contacts.phone;

    final text = Padding(
      padding: EdgeInsets.all(context.fluid(28, 80)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(child: Tag('Inizia da qui', number: '07', dark: true)),
          const SizedBox(height: 24),
          RevealTitle(
            c.ctaTitle,
            style: siteHead(context.fluid(46, 96), color: Colors.white),
            accentLast: true,
          ),
          const SizedBox(height: 22),
          Reveal(
            delay: const Duration(milliseconds: 200),
            child: Text(c.ctaText, style: siteBody(17, color: Site.mutedDark)),
          ),
          const SizedBox(height: 34),
          Reveal(
            delay: const Duration(milliseconds: 300),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SiteButton(
                  'Richiedi sopralluogo',
                  onTap: () => context.go('/contatti'),
                ),
                if (phone.isNotEmpty)
                  SiteButton(
                    phone,
                    kind: ButtonKind.light,
                    icon: Icons.call_outlined,
                    onTap: () => openUrl('tel:${phoneDigits(phone)}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    final image = ParallaxImage(c.ctaImage, extent: 0.25, dark: true);

    return Container(
      color: Site.graphite,
      // Su schermi larghi la foto occupa la metà destra, alta quanto il testo.
      child: wide
          ? Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 600),
                        child: Center(child: text),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      const Spacer(),
                      Expanded(child: image),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(aspectRatio: 16 / 10, child: image),
                text,
              ],
            ),
    );
  }
}
