import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'site_theme.dart';

/// Applica la tavolozza scelta a tutto il sito: quando cambia, i colori
/// sfumano dalla vecchia alla nuova e ogni parte della pagina si ridisegna,
/// senza perdere la posizione di lettura o lo stato dei moduli.
class ThemeFader extends StatefulWidget {
  const ThemeFader({super.key, required this.child});
  final Widget child;

  @override
  State<ThemeFader> createState() => _ThemeFaderState();
}

class _ThemeFaderState extends State<ThemeFader>
    with SingleTickerProviderStateMixin {
  late final AppState _state = context.read<AppState>();
  late SiteTheme _from = _state.currentTheme;
  late SiteTheme _to = _from;
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..addListener(_tick);

  @override
  void initState() {
    super.initState();
    Site.current = _to;
    _state.addListener(_onState);
  }

  void _onState() {
    final target = _state.currentTheme;
    if (target.id == _to.id) return;
    _from = Site.current;
    _to = target;
    _c.forward(from: 0);
  }

  void _tick() {
    Site.current = SiteTheme.lerp(
      _from,
      _to,
      Curves.easeInOutCubic.transform(_c.value),
    );
    _rebuildAll();
  }

  /// Segna da ricostruire ogni elemento: i colori sono letti al momento della
  /// costruzione, anche dai widget costanti.
  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    if (mounted) (context as Element).visitChildren(mark);
  }

  @override
  void dispose() {
    _state.removeListener(_onState);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
