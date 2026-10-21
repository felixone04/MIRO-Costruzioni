import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/site_theme.dart';
import 'common.dart';

/// Confronto "prima / dopo": si trascina la maniglia (o si tocca un punto)
/// per scoprire una foto sotto l'altra.
class CompareSlider extends StatefulWidget {
  const CompareSlider({
    super.key,
    required this.before,
    required this.after,
    this.aspect = 16 / 9,
  });
  final String before;
  final String after;
  final double aspect;

  @override
  State<CompareSlider> createState() => _CompareSliderState();
}

class _CompareSliderState extends State<CompareSlider>
    with SingleTickerProviderStateMixin {
  double _t = 0.5;
  bool _touched = false;

  // Un piccolo movimento d'invito finché nessuno ha toccato la maniglia.
  late final _hint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _hint.addListener(() {
      if (_touched) return;
      setState(() => _t = 0.5 + 0.12 * math.sin(2 * math.pi * _hint.value));
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && !_touched) _hint.forward();
    });
  }

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  void _set(double dx, double width) {
    _touched = true;
    _hint.stop();
    setState(() => _t = (dx / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Reveal(
      child: AspectRatio(
        aspectRatio: widget.aspect,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) => _set(d.localPosition.dx, w),
                onTapDown: (d) => _set(d.localPosition.dx, w),
                child: Rounded(
                  radius: context.isPhone ? 20 : 28,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PhotoImage(widget.after),
                      ClipRect(
                        clipper: _LeftClip(_t),
                        child: PhotoImage(widget.before),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: _Label('Prima', visible: _t > 0.12),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: _Label('Dopo', visible: _t < 0.88),
                      ),
                      Positioned(
                        left: w * _t - 1,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: const ColoredBox(color: Colors.white),
                      ),
                      Positioned(
                        left: w * _t - 26,
                        top: box.maxHeight / 2 - 26,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Site.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 18),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chevron_left_rounded,
                                color: Site.onAccent,
                                size: 22,
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Site.onAccent,
                                size: 22,
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
          },
        ),
      ),
    );
  }
}

class _LeftClip extends CustomClipper<Rect> {
  _LeftClip(this.t);
  final double t;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);
  @override
  bool shouldReclip(_LeftClip old) => old.t != t;
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.visible});
  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: visible ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(text, style: siteLabel(13, color: Colors.white)),
    ),
  );
}
