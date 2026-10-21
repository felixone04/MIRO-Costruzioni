import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/site_theme.dart';

/// Quadratino che riassume una tavolozza: fondo scuro, fondo chiaro e accento.
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
        border: Border.all(
          color: selected ? Site.accent : Colors.white24,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: CustomPaint(
        painter: _SwatchPainter(theme),
        size: Size.square(size),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.t);
  final SiteTheme t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = t.night);
    canvas.drawRect(
      Rect.fromLTWH(w / 2, 0, w / 2, h),
      Paint()..color = t.concrete,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
      Paint()..color = t.accent,
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter o) => o.t != t;
}

/// Pulsante fisso "Colori": apre l'elenco delle tavolozze e le applica al
/// volo a tutto il sito, per vedere le stesse pagine con tonalità diverse.
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
    final maxW = (context.w - 28).clamp(200.0, 290.0);

    final panel = Container(
      width: maxW,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
      decoration: BoxDecoration(
        color: Site.night,
        border: Border.all(color: Site.lineDark),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Text(
              'SCEGLI LE TONALITÀ',
              style: siteMono(10.5, color: Site.mutedDark),
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
                height: context.isPhone ? 50 : 54,
                padding: EdgeInsets.only(
                  left: 8,
                  right: !_open && context.isPhone ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: Site.night,
                  border: Border.all(color: Site.accent, width: 1.4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ThemeSwatch(theme: current, size: 32),
                    const SizedBox(width: 10),
                    Icon(
                      _open ? Icons.close_rounded : Icons.palette_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    // Da telefono, chiuso, resta solo l'icona: copre meno.
                    if (_open || !context.isPhone) ...[
                      const SizedBox(width: 8),
                      Text(
                        _open ? 'CHIUDI' : 'COLORI',
                        style: siteMono(
                          11.5,
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
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
      label: 'Tonalità ${th.name}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: widget.selected || _hover
                ? Colors.white.withValues(alpha: widget.selected ? 0.09 : 0.05)
                : Colors.transparent,
            child: Row(
              children: [
                ThemeSwatch(theme: th, size: 32, selected: widget.selected),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    th.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: siteHead(20, color: Colors.white, height: 1.1),
                  ),
                ),
                // Il colore d'accento della tavolozza come anteprima.
                Container(width: 10, height: 10, color: th.accent),
                if (widget.selected) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.check_rounded, size: 18, color: Site.accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
