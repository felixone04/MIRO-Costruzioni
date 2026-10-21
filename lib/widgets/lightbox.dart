import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/site_theme.dart';
import 'common.dart';

/// Foto a tutto schermo: scorrimento, frecce, tastiera e didascalie.
Future<void> openLightbox(
  BuildContext context,
  List<ProjectPhoto> photos,
  int index,
) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => _Lightbox(photos: photos, initial: index),
    transitionsBuilder: (_, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  ),
);

class _Lightbox extends StatefulWidget {
  const _Lightbox({required this.photos, required this.initial});
  final List<ProjectPhoto> photos;
  final int initial;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late final _pc = PageController(initialPage: widget.initial);
  late int _i = widget.initial;
  final _focus = FocusNode();

  @override
  void dispose() {
    _pc.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(int d) {
    final n = (_i + d).clamp(0, widget.photos.length - 1);
    if (n == _i) return;
    _pc.animateToPage(
      n,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photos[_i];
    final narrow = MediaQuery.sizeOf(context).width < 700;
    Widget arrow(IconData icon, int d, bool enabled) => IconButton(
      onPressed: enabled ? () => _go(d) : null,
      iconSize: 30,
      color: Colors.white,
      disabledColor: Colors.white24,
      icon: Icon(icon),
      tooltip: d < 0 ? 'Precedente' : 'Successiva',
    );
    return KeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (e) {
        if (e is! KeyDownEvent) return;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) _go(1);
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) _go(-1);
        if (e.logicalKey == LogicalKeyboardKey.escape) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Text(
                      '${(_i + 1).toString().padLeft(2, '0')} / ${widget.photos.length.toString().padLeft(2, '0')}',
                      style: siteMono(13, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                      tooltip: 'Chiudi',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    if (!narrow) arrow(Icons.arrow_back_rounded, -1, _i > 0),
                    Expanded(
                      child: PageView.builder(
                        controller: _pc,
                        itemCount: widget.photos.length,
                        onPageChanged: (i) => setState(() => _i = i),
                        itemBuilder: (_, i) => InteractiveViewer(
                          maxScale: 4,
                          child: PhotoImage(
                            widget.photos[i].url,
                            fit: BoxFit.contain,
                            dark: true,
                          ),
                        ),
                      ),
                    ),
                    if (!narrow)
                      arrow(
                        Icons.arrow_forward_rounded,
                        1,
                        _i < widget.photos.length - 1,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    if (narrow) arrow(Icons.arrow_back_rounded, -1, _i > 0),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          p.caption,
                          key: ValueKey(_i),
                          textAlign: TextAlign.center,
                          style: siteBody(15, color: Colors.white70),
                        ),
                      ),
                    ),
                    if (narrow)
                      arrow(
                        Icons.arrow_forward_rounded,
                        1,
                        _i < widget.photos.length - 1,
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
}
