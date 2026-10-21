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

/// Struttura comune delle pagine pubbliche: barra in alto (si nasconde
/// scorrendo in giù), sottile barra di avanzamento, menu a tutto schermo su
/// telefono e piè di pagina.
class SiteScaffold extends StatefulWidget {
  const SiteScaffold({
    super.key,
    required this.current,
    required this.children,
    this.overHero = false,
  });
  final String current;
  final List<Widget> children;

  /// La pagina inizia con una foto scura: la barra parte trasparente.
  final bool overHero;

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
    final solid = p.pixels > 40;
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
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              top: _hidden && !_menu ? -navH - 4 : 0,
              left: 0,
              right: 0,
              height: navH,
              child: _Header(
                transparent: widget.overHero && !_solid && !_menu,
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
              height: 2,
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
    required this.transparent,
    required this.current,
    required this.menuOpen,
    required this.onGo,
    required this.onMenu,
  });
  final bool transparent;
  final String current;
  final bool menuOpen;
  final ValueChanged<String> onGo;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final wide = context.w >= 900;
    final fg = transparent ? Colors.white : Site.ink;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : Site.paper,
        gradient: transparent
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0),
                ],
              )
            : null,
        border: Border(
          bottom: BorderSide(
            color: transparent || menuOpen ? Colors.transparent : Site.line,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: context.gutter),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onGo('/'),
              child: BrandLogo(
                height: context.fluid(34, 40),
                light: transparent,
              ),
            ),
          ),
          const Spacer(),
          if (wide)
            for (final (label, path) in navItems)
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: HoverLink(
                  label,
                  active: current.startsWith(path),
                  onTap: () => onGo(path),
                  style: siteLabel(15, color: fg, weight: FontWeight.w500),
                ),
              )
          else
            _MenuButton(open: menuOpen, color: fg, onTap: onMenu),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.open,
    required this.color,
    required this.onTap,
  });
  final bool open;
  final Color color;
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
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
                bar(open ? math.pi / 4 : 0, open ? 0 : -4, 24),
                bar(open ? -math.pi / 4 : 0, open ? 0 : 4, open ? 24 : 16),
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
      color: Site.paper,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(context.gutter, 20, context.gutter, 32),
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
                      offset: Offset(0, 20 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onGo(items[i].$2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        items[i].$1,
                        style: siteHead(
                          context.fluid(40, 54),
                          color:
                              (items[i].$2 == '/'
                                  ? current == '/'
                                  : current.startsWith(items[i].$2))
                              ? Site.accent
                              : Site.ink,
                          italic: items[i].$2 == '/'
                              ? current == '/'
                              : current.startsWith(items[i].$2),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              Container(height: 1, color: Site.line),
              const SizedBox(height: 22),
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
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Site.accentDeep),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: siteBody(15, color: Site.muted)),
          ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------------- footer

class _Footer extends StatelessWidget {
  const _Footer({required this.onGo});
  final ValueChanged<String> onGo;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final content = s.content;
    final c = content.contacts;
    final wide = context.w >= 900;
    final linkStyle = siteBody(15, color: Colors.white, height: 1.4);

    Widget col(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: siteLabel(13, color: Site.mutedDark)),
        const SizedBox(height: 14),
        ...children,
      ],
    );

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandLogo(height: 44, light: true),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            content.footerText,
            style: siteBody(14.5, color: Site.mutedDark),
          ),
        ),
      ],
    );

    final nav = col('Pagine', [
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
      for (final (label, url) in [
        ('Instagram', c.instagram),
        ('Facebook', c.facebook),
        ('LinkedIn', c.linkedin),
      ])
        if (url.isNotEmpty)
          HoverLink(label, onTap: () => openUrl(url), style: linkStyle),
    ]);

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.isPhone ? 8 : 14,
        0,
        context.isPhone ? 8 : 14,
        context.isPhone ? 8 : 14,
      ),
      decoration: BoxDecoration(
        color: Site.night,
        borderRadius: BorderRadius.circular(context.isPhone ? 20 : 28),
      ),
      padding: EdgeInsets.fromLTRB(
        context.gutter,
        context.fluid(52, 84),
        context.gutter,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: brand),
                    const SizedBox(width: 40),
                    Expanded(flex: 2, child: nav),
                    Expanded(flex: 3, child: contacts),
                  ],
                )
              else ...[
                brand,
                const SizedBox(height: 36),
                nav,
                const SizedBox(height: 30),
                contacts,
              ],
              SizedBox(height: context.fluid(40, 64)),
              Container(height: 1, color: Site.lineDark),
              const SizedBox(height: 18),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '© ${DateTime.now().year} ${content.companyName}'
                    '${c.vat.isNotEmpty ? ' · ${c.vat}' : ''}',
                    style: siteBody(12.5, color: Site.mutedDark),
                  ),
                  HoverLink(
                    'Area riservata',
                    onTap: () => context.go('/admin'),
                    style: siteBody(12.5, color: Site.mutedDark),
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

/// Inizio delle pagine interne: etichetta, titolo che sale e due righe di
/// testo, sul fondo della pagina.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.text = '',
    this.bottom,
  });
  final String kicker;
  final String title;
  final String text;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Section(
      top: context.navH + context.fluid(40, 90),
      bottom: context.fluid(30, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kicker.isNotEmpty) ...[
            Reveal(child: Kicker(kicker)),
            const SizedBox(height: 18),
          ],
          RevealTitle(
            title,
            delay: const Duration(milliseconds: 80),
            style: siteHead(context.fluid(46, 104), height: 1.0),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 22),
            Reveal(
              delay: const Duration(milliseconds: 300),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  text,
                  style: siteBody(context.fluid(16, 18.5), color: Site.muted),
                ),
              ),
            ),
          ],
          if (bottom != null) ...[
            SizedBox(height: context.fluid(28, 44)),
            Reveal(delay: const Duration(milliseconds: 400), child: bottom!),
          ],
        ],
      ),
    );
  }
}

/// Filtri discreti: parole in fila, quella scelta in evidenza e
/// sottolineata. Su telefono scorrono di lato.
class QuietFilters extends StatelessWidget {
  const QuietFilters({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == options.length - 1 ? 0 : 26),
            child: HoverLink(
              options[i],
              active: i == selected,
              onTap: () => onSelect(i),
              style: siteBody(
                15,
                height: 1.3,
                weight: i == selected ? FontWeight.w600 : FontWeight.w400,
                color: i == selected ? Site.ink : Site.muted,
              ),
            ),
          ),
      ],
    );
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: row);
  }
}
