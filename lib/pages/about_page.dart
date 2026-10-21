import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import '../widgets/common.dart';
import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content;
    return SiteScaffold(
      current: '/azienda',
      children: [
        PageHero(
          kicker: c.aboutKicker,
          title: c.aboutTitle,
          text: c.aboutIntro,
          image: c.aboutImage,
        ),
        const _Story(),
        if (c.values.isNotEmpty) const _Values(),
        if (c.timeline.isNotEmpty) const _Timeline(),
        if (c.team.isNotEmpty) const _Team(),
        const Ticker(),
        const CtaSection(),
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
      height: wide ? 640 : context.fluid(360, 560),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: wide ? 90 : 50,
            bottom: wide ? 140 : 90,
            child: Reveal(child: ParallaxImage(c.aboutImage2)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: wide ? 260 : 170,
            height: wide ? 300 : 190,
            child: Reveal(
              delay: const Duration(milliseconds: 250),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Site.paper, width: 8),
                ),
                child: PhotoImage(c.aboutImage),
              ),
            ),
          ),
          Positioned(
            left: wide ? 24 : 14,
            bottom: wide ? 160 : 104,
            child: Reveal(
              delay: const Duration(milliseconds: 400),
              child: Container(
                color: Site.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAL',
                      style: siteMono(
                        11,
                        weight: FontWeight.w600,
                        color: Site.onAccent,
                      ),
                    ),
                    Text(
                      c.timeline.isNotEmpty ? c.timeline.first.year : '1987',
                      style: siteHead(
                        44,
                        weight: FontWeight.w700,
                        height: 1,
                        color: Site.onAccent,
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
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Reveal(child: Tag('La nostra storia', number: '01')),
        const SizedBox(height: 26),
        for (final para in c.aboutText.split('\n\n'))
          if (para.trim().isNotEmpty)
            Reveal(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  para.trim(),
                  style: siteBody(context.fluid(16, 18.5), color: Site.muted),
                ),
              ),
            ),
        if (c.certifications.isNotEmpty) ...[
          const SizedBox(height: 18),
          Reveal(
            child: Text(
              'CERTIFICAZIONI',
              style: siteMono(11.5, color: Site.accentDeep),
            ),
          ),
          const SizedBox(height: 12),
          Reveal(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cert in c.certifications)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Site.ink, width: 1.2),
                    ),
                    child: Text(
                      cert.toUpperCase(),
                      style: siteMono(11, weight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return Section(
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: images),
                const SizedBox(width: 80),
                Expanded(flex: 5, child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [images, const SizedBox(height: 40), text],
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
    final initials = c.values
        .map((v) => v.title.isEmpty ? '' : v.title[0].toUpperCase())
        .join('.');
    return Section(
      color: Site.night,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            kicker: 'I nostri valori',
            number: '02',
            title: 'Quattro lettere,\n$initials.',
            dark: true,
          ),
          SizedBox(height: context.fluid(40, 80)),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 1000
                  ? 4
                  : (box.maxWidth >= 560 ? 2 : 1);
              final w = box.maxWidth / cols;
              return Wrap(
                children: [
                  for (var i = 0; i < c.values.length; i++)
                    SizedBox(
                      width: w,
                      child: Reveal(
                        delay: Duration(milliseconds: 120 * (i % cols)),
                        child: _ValueCard(
                          value: c.values[i],
                          first: i % cols == 0,
                        ),
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
  const _ValueCard({required this.value, required this.first});
  final Highlight value;
  final bool first;

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
        padding: EdgeInsets.fromLTRB(widget.first ? 0 : 24, 30, 24, 34),
        decoration: BoxDecoration(
          color: _hover ? Site.graphite : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: _hover ? Site.accent : Site.lineDark,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              v.title.isEmpty ? '' : v.title[0].toUpperCase(),
              style: _hover
                  ? siteHead(
                      context.fluid(90, 140),
                      color: Site.accent,
                      weight: FontWeight.w700,
                      height: 0.85,
                    )
                  : siteOutline(
                      context.fluid(90, 140),
                      color: Colors.white54,
                      stroke: 1.3,
                      height: 0.85,
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              v.title.toUpperCase(),
              style: siteHead(30, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(v.text, style: siteBody(15, color: Site.mutedDark)),
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
    final wide = context.w >= 900;
    return Section(
      color: Site.concrete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            kicker: 'Le tappe',
            number: '03',
            title: 'Una storia\nmattone dopo mattone.',
          ),
          SizedBox(height: context.fluid(40, 80)),
          for (var i = 0; i < c.timeline.length; i++)
            Reveal(
              delay: const Duration(milliseconds: 80),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: context.fluid(22, 34)),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Site.line)),
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 260,
                            child: Text(
                              c.timeline[i].year,
                              style: siteHead(
                                76,
                                weight: FontWeight.w700,
                                height: 0.9,
                                color: i == c.timeline.length - 1
                                    ? Site.accentDeep
                                    : Site.ink,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              c.timeline[i].title.toUpperCase(),
                              style: siteHead(36),
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
                              56,
                              weight: FontWeight.w700,
                              color: Site.accentDeep,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            c.timeline[i].title.toUpperCase(),
                            style: siteHead(28),
                          ),
                          const SizedBox(height: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            kicker: 'Le persone',
            number: '04',
            title: 'Chi guida\ni cantieri.',
          ),
          SizedBox(height: context.fluid(40, 70)),
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth >= 1000
                  ? 4
                  : (box.maxWidth >= 520 ? 2 : 1);
              final gap = context.fluid(16, 28);
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap * 1.6,
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
            child: ClipRect(
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
          const SizedBox(height: 16),
          Text(m.name.toUpperCase(), style: siteHead(28)),
          const SizedBox(height: 4),
          Text(
            m.role.toUpperCase(),
            style: siteMono(11.5, color: Site.accentDeep),
          ),
        ],
      ),
    );
  }
}
