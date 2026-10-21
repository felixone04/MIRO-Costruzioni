import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/site_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = s.content;
    return SiteScaffold(
      current: '/azienda',
      children: [
        PageHeader(
          kicker: c.aboutKicker,
          title: c.aboutTitle,
          text: c.aboutIntro,
        ),
        const _Story(),
        if (c.values.isNotEmpty) const _Values(),
        if (c.timeline.isNotEmpty) const _Timeline(),
        if (c.team.isNotEmpty) const _Team(),
        if (s.publishedTestimonials.isNotEmpty) const _Testimonials(),
      ],
    );
  }
}

class _Story extends StatelessWidget {
  const _Story();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 980;
    final images = SizedBox(
      height: wide ? 600 : context.fluid(340, 520),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: wide ? 90 : 46,
            bottom: wide ? 120 : 80,
            child: Reveal(child: Rounded(child: ParallaxImage(c.aboutImage))),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: wide ? 250 : 160,
            height: wide ? 290 : 180,
            child: Reveal(
              delay: const Duration(milliseconds: 250),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Site.paper,
                  borderRadius: BorderRadius.circular(Radii.photo + 7),
                ),
                child: Rounded(child: PhotoImage(c.aboutImage2)),
              ),
            ),
          ),
        ],
      ),
    );
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final para in c.aboutText.split('\n\n'))
          if (para.trim().isNotEmpty)
            Reveal(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  para.trim(),
                  style: siteBody(context.fluid(16, 18), color: Site.muted),
                ),
              ),
            ),
        if (c.certifications.isNotEmpty) ...[
          const SizedBox(height: 10),
          Reveal(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cert in c.certifications)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Site.line),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(cert, style: siteBody(13.5, height: 1.3)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return Section(
      top: 0,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: images),
                const SizedBox(width: 70),
                Expanded(flex: 5, child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [images, const SizedBox(height: 36), text],
            ),
    );
  }
}

/// I valori: le loro iniziali compongono il nome dell'impresa.
class _Values extends StatelessWidget {
  const _Values();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    return Section(
      color: Site.concrete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            kicker: 'Il nome',
            title: 'Quattro parole\nche ci tengono insieme.',
          ),
          SizedBox(height: context.fluid(34, 60)),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 1000
                  ? 4
                  : (box.maxWidth >= 540 ? 2 : 1);
              const gap = 14.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < c.values.length; i++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 110 * (i % cols)),
                        child: _ValueCard(value: c.values[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatefulWidget {
  const _ValueCard({required this.value});
  final Highlight value;

  @override
  State<_ValueCard> createState() => _ValueCardState();
}

class _ValueCardState extends State<_ValueCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -6 : 0, 0),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        decoration: BoxDecoration(
          color: Site.surface,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v.title.isEmpty ? '' : v.title[0].toUpperCase(),
              style: siteHead(
                context.fluid(64, 84),
                color: Site.accent,
                italic: true,
                height: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(v.title, style: siteHead(26)),
            const SizedBox(height: 8),
            Text(v.text, style: siteBody(15, color: Site.muted)),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    final wide = context.w >= 860;
    return Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            kicker: 'La storia',
            title: 'Un cantiere\ndopo l\'altro.',
          ),
          SizedBox(height: context.fluid(30, 56)),
          for (var i = 0; i < c.timeline.length; i++)
            Reveal(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: context.fluid(20, 28)),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Site.line)),
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 200,
                            child: Text(
                              c.timeline[i].year,
                              style: siteHead(
                                48,
                                color: Site.accent,
                                italic: true,
                                height: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              c.timeline[i].title,
                              style: siteHead(28),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            flex: 5,
                            child: Text(
                              c.timeline[i].text,
                              style: siteBody(16, color: Site.muted),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.timeline[i].year,
                            style: siteHead(
                              38,
                              color: Site.accent,
                              italic: true,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(c.timeline[i].title, style: siteHead(24)),
                          const SizedBox(height: 6),
                          Text(
                            c.timeline[i].text,
                            style: siteBody(15.5, color: Site.muted),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team();

  @override
  Widget build(BuildContext context) {
    final team = context.watch<AppState>().content.team;
    return Section(
      top: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            kicker: 'Le persone',
            title: 'Chi trovi\nin cantiere.',
          ),
          SizedBox(height: context.fluid(30, 56)),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 1000
                  ? 4
                  : (box.maxWidth >= 500 ? 2 : 1);
              final gap = context.fluid(14, 24);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap * 1.5,
                children: [
                  for (var i = 0; i < team.length; i++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 100 * (i % cols)),
                        child: _Person(member: team[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Foto in bianco e nero che prende colore al passaggio del mouse.
class _Person extends StatefulWidget {
  const _Person({required this.member});
  final TeamMember member;

  @override
  State<_Person> createState() => _PersonState();
}

class _PersonState extends State<_Person> {
  bool _hover = false;

  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
  static const _none = ColorFilter.mode(Colors.transparent, BlendMode.dst);

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Rounded(
              child: AnimatedScale(
                scale: _hover ? 1.05 : 1,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                child: ColorFiltered(
                  colorFilter: _hover ? _none : _grey,
                  child: PhotoImage(m.photo, alignment: Alignment.topCenter),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(m.name, style: siteHead(24)),
          const SizedBox(height: 2),
          Text(m.role, style: siteBody(14.5, color: Site.muted)),
        ],
      ),
    );
  }
}

/// Le parole dei clienti, una alla volta.
class _Testimonials extends StatefulWidget {
  const _Testimonials();

  @override
  State<_Testimonials> createState() => _TestimonialsState();
}

class _TestimonialsState extends State<_Testimonials> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    final t = list[_i % list.length];
    return Section(
      top: 0,
      child: Reveal(
        child: Container(
          padding: EdgeInsets.all(context.fluid(28, 70)),
          decoration: BoxDecoration(
            color: Site.concrete,
            borderRadius: BorderRadius.circular(context.isPhone ? 22 : 30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Kicker('Dicono di noi'),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                layoutBuilder: (cur, prev) => Stack(
                  alignment: Alignment.topLeft,
                  children: [...prev, ?cur],
                ),
                child: Column(
                  key: ValueKey(t.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Text(
                        '«${t.text}»',
                        style: siteHead(
                          context.fluid(24, 38),
                          italic: true,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      [t.name, t.role].where((e) => e.isNotEmpty).join(' · '),
                      style: siteBody(15, color: Site.muted),
                    ),
                  ],
                ),
              ),
              if (list.length > 1) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (var n = 0; n < list.length; n++)
                      GestureDetector(
                        onTap: () => setState(() => _i = n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: n == _i % list.length ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: n == _i % list.length
                                ? Site.accent
                                : Site.line,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
