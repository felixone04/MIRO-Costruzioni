import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import 'brand_logo.dart';
import 'common.dart';
import 'theme_switcher.dart';

const navItems = <(String, String)>[
  ('Progetti', '/progetti'),
  ('Servizi', '/servizi'),
  ('Azienda', '/azienda'),
  ('Contatti', '/contatti'),
];

/// Dà alle sezioni accesso allo scorrimento della pagina (parallasse della
/// prima schermata).
class SiteScroll extends InheritedWidget {
  const SiteScroll({super.key, required this.controller, required super.child});
  final ScrollController controller;

  static ScrollController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SiteScroll>()?.controller;

  @override
  bool updateShouldNotify(SiteScroll old) => old.controller != controller;
}

/// Struttura comune delle pagine pubbliche: barra in alto (trasparente sopra
/// la prima foto, poi scura; si nasconde scorrendo in giù), barra di
/// avanzamento, menu a tutto schermo su telefono e piè di pagina.
class SiteScaffold extends StatefulWidget {
  const SiteScaffold({
    super.key,
    required this.current,
    required this.children,
  });
  final String current;
  final List<Widget> children;

  @override
  State<SiteScaffold> createState() => _SiteScaffoldState();
}

class _SiteScaffoldState extends State<SiteScaffold> {
  final _scroll = ScrollController();
  bool _menu = false;
  bool _solid = false;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final p = _scroll.position;
    final solid = p.pixels > 60;
    // Nascosta mentre si scende, ricompare appena si risale.
    final hidden =
        p.pixels > 400 && p.userScrollDirection == ScrollDirection.reverse;
    final show = p.userScrollDirection == ScrollDirection.forward;
    if (solid != _solid ||
        (hidden && !_hidden) ||
        (show && _hidden) ||
        (p.pixels <= 400 && _hidden)) {
      setState(() {
        _solid = solid;
        if (hidden) _hidden = true;
        if (show || p.pixels <= 400) _hidden = false;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _go(String path) {
    setState(() => _menu = false);
    if (path == widget.current) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navH = context.navH;
    return Scaffold(
      backgroundColor: Site.paper,
      body: SiteScroll(
        controller: _scroll,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...widget.children,
                    _Footer(onGo: _go),
                  ],
                ),
              ),
            ),
            // Barra in alto.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              top: _hidden && !_menu ? -navH - 4 : 0,
              left: 0,
              right: 0,
              height: navH,
              child: _Header(
                solid: _solid && !_menu,
                current: widget.current,
                menuOpen: _menu,
                onGo: _go,
                onMenu: () => setState(() => _menu = !_menu),
              ),
            ),
            // Avanzamento della lettura.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, _) {
                    var t = 0.0;
                    if (_scroll.hasClients &&
                        _scroll.position.hasContentDimensions &&
                        _scroll.position.maxScrollExtent > 0) {
                      t = (_scroll.offset / _scroll.position.maxScrollExtent)
                          .clamp(0.0, 1.0);
                    }
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: t,
                      child: ColoredBox(color: Site.accent),
                    );
                  },
                ),
              ),
            ),
            if (_menu)
              Positioned.fill(
                top: navH,
                child: _MobileMenu(current: widget.current, onGo: _go),
              ),
            // Pulsante "Colori" (se il gestionale lo rende visibile).
            if (!_menu && context.watch<AppState>().switcherVisible)
              Positioned(
                left: context.isPhone ? 14 : 22,
                bottom: context.isPhone ? 14 : 22,
                child: const SafeArea(child: ThemeSwitcher()),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({
    required this.solid,
    required this.current,
    required this.menuOpen,
    required this.onGo,
    required this.onMenu,
  });
  final bool solid;
  final String current;
  final bool menuOpen;
  final ValueChanged<String> onGo;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final wide = context.w >= 1024;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: menuOpen
            ? Site.night
            : (solid ? Site.night.withValues(alpha: 0.96) : Colors.transparent),
        gradient: solid || menuOpen
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0),
                ],
              ),
        border: Border(
          bottom: BorderSide(color: solid ? Site.lineDark : Colors.transparent),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: context.gutter),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onGo('/'),
              child: BrandLogo(height: context.fluid(34, 42), light: true),
            ),
          ),
          const Spacer(),
          if (wide) ...[
            for (final (label, path) in navItems)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HoverLink(
                  label.toUpperCase(),
                  active: current.startsWith(path),
                  onTap: () => onGo(path),
                  style: siteMono(
                    12.5,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 18),
            SiteButton('Richiedi sopralluogo', onTap: () => onGo('/contatti')),
          ] else
            _MenuButton(open: menuOpen, onTap: onMenu),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget bar(double angle, double dy, double width) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: width,
      height: 2,
      transform: Matrix4.translationValues(0, dy, 0)..rotateZ(angle),
      transformAlignment: Alignment.center,
      color: Colors.white,
    );
    return Semantics(
      button: true,
      label: open ? 'Chiudi menu' : 'Apri menu',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                bar(open ? math.pi / 4 : 0, open ? 0 : -5, 26),
                bar(open ? -math.pi / 4 : 0, open ? 0 : 5, open ? 26 : 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({required this.current, required this.onGo});
  final String current;
  final ValueChanged<String> onGo;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppState>().content.contacts;
    final items = [('Home', '/'), ...navItems];
    return Material(
      color: Site.night,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.gutter, 24, context.gutter, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 500 + i * 90),
                  curve: Interval(i * 0.1, 1, curve: Curves.easeOutCubic),
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onGo(items[i].$2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Site.lineDark),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '0${i + 1}',
                            style: siteMono(12, color: Site.accent),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              items[i].$1.toUpperCase(),
                              style: siteHead(
                                context.fluid(40, 56),
                                color:
                                    (items[i].$2 == '/'
                                        ? current == '/'
                                        : current.startsWith(items[i].$2))
                                    ? Site.accent
                                    : Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Site.mutedDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 34),
              SiteButton(
                'Richiedi sopralluogo',
                onTap: () => onGo('/contatti'),
              ),
              const SizedBox(height: 34),
              if (c.phone.isNotEmpty)
                _MenuContact(
                  icon: Icons.call_outlined,
                  text: c.phone,
                  onTap: () => openUrl('tel:${phoneDigits(c.phone)}'),
                ),
              if (c.email.isNotEmpty)
                _MenuContact(
                  icon: Icons.mail_outline_rounded,
                  text: c.email,
                  onTap: () => openUrl('mailto:${c.email}'),
                ),
              if (c.address.isNotEmpty)
                _MenuContact(
                  icon: Icons.place_outlined,
                  text: c.address,
                  onTap: () => openUrl(mapsUrl(c.address)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuContact extends StatelessWidget {
  const _MenuContact({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Site.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: siteBody(15, color: Site.mutedDark)),
          ),
        ],
      ),
    ),
  );
}

String mapsUrl(String address) =>
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

// ------------------------------------------------------------------- footer

class _Footer extends StatelessWidget {
  const _Footer({required this.onGo});
  final ValueChanged<String> onGo;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final content = s.content;
    final c = content.contacts;
    final wide = context.w >= 980;
    final mid = context.w >= 640;
    final linkStyle = siteBody(15, color: Colors.white, height: 1.4);

    Widget col(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: siteMono(11.5, color: Site.accent)),
        const SizedBox(height: 18),
        ...children,
      ],
    );

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandLogo(height: 46, light: true),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            content.footerText,
            style: siteBody(14.5, color: Site.mutedDark),
          ),
        ),
        if (content.certifications.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cert in content.certifications)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Site.lineDark),
                  ),
                  child: Text(
                    cert,
                    style: siteMono(10.5, color: Site.mutedDark),
                  ),
                ),
            ],
          ),
        ],
      ],
    );

    final nav = col('Esplora', [
      for (final (label, path) in [('Home', '/'), ...navItems])
        HoverLink(label, onTap: () => onGo(path), style: linkStyle),
    ]);

    final contacts = col('Contatti', [
      if (c.address.isNotEmpty)
        HoverLink(
          c.address,
          onTap: () => openUrl(mapsUrl(c.address)),
          style: linkStyle,
        ),
      if (c.phone.isNotEmpty)
        HoverLink(
          c.phone,
          onTap: () => openUrl('tel:${phoneDigits(c.phone)}'),
          style: linkStyle,
        ),
      if (c.email.isNotEmpty)
        HoverLink(
          c.email,
          onTap: () => openUrl('mailto:${c.email}'),
          style: linkStyle,
        ),
      if (c.hours.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(c.hours, style: siteBody(13.5, color: Site.mutedDark)),
        ),
    ]);

    final social = col('Seguici', [
      for (final (label, url) in [
        ('Instagram', c.instagram),
        ('Facebook', c.facebook),
        ('LinkedIn', c.linkedin),
      ])
        if (url.isNotEmpty)
          HoverLink(label, onTap: () => openUrl(url), style: linkStyle),
      if (c.whatsapp.isNotEmpty)
        HoverLink(
          'WhatsApp',
          onTap: () => openUrl(
            'https://wa.me/${phoneDigits(c.whatsapp).replaceAll('+', '')}',
          ),
          style: linkStyle,
        ),
    ]);

    return Container(
      color: Site.night,
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        context.fluid(64, 110),
        context.gutter,
        28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grande scritta che sale quando si arriva in fondo.
              Reveal(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content.heroTitle.replaceAll('\n', ' ').toUpperCase(),
                    maxLines: 1,
                    style: siteHead(
                      context.fluid(46, 150),
                      color: Colors.white.withValues(alpha: 0.08),
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.fluid(40, 70)),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: brand),
                    const SizedBox(width: 40),
                    Expanded(flex: 2, child: nav),
                    Expanded(flex: 3, child: contacts),
                    Expanded(flex: 2, child: social),
                  ],
                )
              else ...[
                brand,
                const SizedBox(height: 44),
                if (mid)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nav),
                      Expanded(flex: 2, child: contacts),
                      Expanded(child: social),
                    ],
                  )
                else ...[
                  nav,
                  const SizedBox(height: 36),
                  contacts,
                  const SizedBox(height: 36),
                  social,
                ],
              ],
              const SizedBox(height: 56),
              Container(height: 1, color: Site.lineDark),
              const SizedBox(height: 22),
              Wrap(
                spacing: 24,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '© ${DateTime.now().year} ${content.companyName}'
                    '${c.vat.isNotEmpty ? ' · ${c.vat}' : ''}',
                    style: siteMono(11, color: Site.mutedDark),
                  ),
                  HoverLink(
                    'AREA RISERVATA',
                    onTap: () => context.go('/admin'),
                    style: siteMono(11, color: Site.mutedDark),
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

/// Prima schermata delle pagine interne: foto con parallasse, velo scuro,
/// etichetta tecnica e titolo che sale.
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.kicker,
    required this.title,
    required this.image,
    this.text = '',
    this.height,
    this.bottom,
  });
  final String kicker;
  final String title;
  final String image;
  final String text;
  final double? height;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final h = height ?? math.max(context.screenH * 0.72, 480.0);
    // Alta almeno [h]: se il testo non ci sta si allunga invece di tagliarlo.
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: Site.night,
            child: ParallaxImage(image, extent: 0.3, dark: true),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Site.night.withValues(alpha: 0.35),
                  Site.night.withValues(alpha: 0.25),
                  Site.night.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: BlueprintGrid()),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: h, minWidth: context.w),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.gutter,
              context.navH + 24,
              context.gutter,
              context.fluid(36, 72),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(child: Tag(kicker, dark: true)),
                    const SizedBox(height: 20),
                    RevealTitle(
                      title,
                      delay: const Duration(milliseconds: 120),
                      style: siteHead(
                        context.fluid(52, 128),
                        color: Colors.white,
                        weight: FontWeight.w700,
                        height: 0.92,
                      ),
                      accentLast: true,
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Reveal(
                        delay: const Duration(milliseconds: 350),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Text(
                            text,
                            style: siteBody(
                              context.fluid(15.5, 18),
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (bottom != null) ...[
                      const SizedBox(height: 28),
                      Reveal(
                        delay: const Duration(milliseconds: 450),
                        child: bottom!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Griglia sottile "da tavola tecnica" sopra le foto scure.
class BlueprintGrid extends StatelessWidget {
  const BlueprintGrid({super.key, this.opacity = 0.07});
  final double opacity;

  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: CustomPaint(painter: _GridPainter(opacity)));
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.opacity);
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;
    const step = 96.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    // Piccole croci di riferimento agli incroci.
    final cross = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 3)
      ..strokeWidth = 1;
    for (var x = step; x < size.width; x += step * 3) {
      for (var y = step; y < size.height; y += step * 3) {
        canvas.drawLine(Offset(x - 5, y), Offset(x + 5, y), cross);
        canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), cross);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.opacity != opacity;
}
