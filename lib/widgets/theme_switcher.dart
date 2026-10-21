import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';

/// Pallino che riassume una tavolozza: metà fondo, metà colore delle scritte.
class ThemeSwatch extends StatelessWidget {
  const ThemeSwatch({
    super.key,
    required this.theme,
    this.size = 30,
    this.selected = false,
  });
  final SiteTheme theme;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      padding: EdgeInsets.all(selected ? 2.5 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Site.accent : Site.line,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _SwatchPainter(theme),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.t);
  final SiteTheme t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(r, Paint()..color = t.paper);
    final p = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = t.accent);
    canvas.drawCircle(r.center, size.width * 0.13, Paint()..color = t.ink);
  }

  @override
  bool shouldRepaint(_SwatchPainter o) => o.t != t;
}

/// Pulsante fisso "Colori": apre l'elenco delle tavolozze e le applica al
/// volo a tutto il sito, per vedere le stesse pagine con atmosfere diverse.
class ThemeSwitcher extends StatefulWidget {
  const ThemeSwitcher({super.key});

  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final current = s.currentTheme;
    final themes = s.offeredThemes;
    final maxW = (context.w - 28).clamp(200.0, 270.0);

    final panel = Container(
      width: maxW,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      decoration: BoxDecoration(
        color: Site.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Site.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Site.dark ? 0.5 : 0.14),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Text(
              'Colori del sito',
              style: siteBody(13, color: Site.muted),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.h * 0.6),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final th in themes)
                    _ThemeRow(
                      theme: th,
                      selected: th.id == current.id,
                      onTap: () => s.selectTheme(th.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomLeft,
          child: _open ? panel : const SizedBox(width: 0, height: 0),
        ),
        Semantics(
          button: true,
          label: _open ? 'Chiudi colori' : 'Cambia colori',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => setState(() => _open = !_open),
              child: Container(
                height: context.isPhone ? 48 : 52,
                padding: EdgeInsets.only(
                  left: 7,
                  right: !_open && context.isPhone ? 7 : 18,
                ),
                decoration: BoxDecoration(
                  color: Site.ink,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemeSwatch(
                      theme: current,
                      size: context.isPhone ? 34 : 38,
                    ),
                    // Da telefono, chiuso, resta solo il pallino: copre meno.
                    if (_open || !context.isPhone) ...[
                      const SizedBox(width: 10),
                      Icon(
                        _open ? Icons.close_rounded : Icons.palette_outlined,
                        size: 18,
                        color: Site.paper,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _open ? 'Chiudi' : 'Colori',
                        style: siteLabel(14, color: Site.paper),
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

class _ThemeRow extends StatefulWidget {
  const _ThemeRow({
    required this.theme,
    required this.selected,
    required this.onTap,
  });
  final SiteTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeRow> createState() => _ThemeRowState();
}

class _ThemeRowState extends State<_ThemeRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final th = widget.theme;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: 'Colori ${th.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected || _hover
                  ? Site.ink.withValues(alpha: widget.selected ? 0.08 : 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ThemeSwatch(theme: th, size: 32, selected: widget.selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(th.name, style: siteHead(19, height: 1.15)),
                      Text(
                        th.dark ? 'Scuro' : 'Chiaro',
                        style: siteBody(12, color: Site.muted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (widget.selected)
                  Icon(Icons.check_rounded, size: 18, color: Site.accentDeep),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
