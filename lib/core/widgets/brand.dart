import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The AgriKonek mark: a sprout whose roots join two farmers (the dots).
/// Drawn in code, so it stays sharp at any size and costs no image asset.
class AgriKonekMark extends StatelessWidget {
  const AgriKonekMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(s * 0.28));
    canvas.drawRRect(
      tile,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.leafLight, AppTheme.leafDark],
        ).createShader(Offset.zero & size),
    );

    final white = Paint()..color = Colors.white;
    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.055;

    // Stem.
    final stem = Path()
      ..moveTo(s * 0.50, s * 0.74)
      ..quadraticBezierTo(s * 0.49, s * 0.58, s * 0.52, s * 0.42);
    canvas.drawPath(stem, line);

    // Right (larger) leaf.
    final right = Path()
      ..moveTo(s * 0.52, s * 0.46)
      ..cubicTo(s * 0.54, s * 0.28, s * 0.70, s * 0.20, s * 0.82, s * 0.20)
      ..cubicTo(s * 0.82, s * 0.36, s * 0.70, s * 0.48, s * 0.52, s * 0.46)
      ..close();
    canvas.drawPath(right, white);

    // Left (smaller) leaf.
    final left = Path()
      ..moveTo(s * 0.49, s * 0.56)
      ..cubicTo(s * 0.47, s * 0.44, s * 0.36, s * 0.36, s * 0.22, s * 0.36)
      ..cubicTo(s * 0.23, s * 0.48, s * 0.33, s * 0.57, s * 0.49, s * 0.56)
      ..close();
    canvas.drawPath(left, white);

    // Roots reaching two farmers: the connection in "Konek".
    final roots = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.04;
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.50, s * 0.74)
          ..quadraticBezierTo(s * 0.40, s * 0.80, s * 0.27, s * 0.78),
        roots);
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.50, s * 0.74)
          ..quadraticBezierTo(s * 0.60, s * 0.80, s * 0.73, s * 0.78),
        roots);
    canvas.drawCircle(Offset(s * 0.24, s * 0.78), s * 0.065, white);
    canvas.drawCircle(
        Offset(s * 0.76, s * 0.78), s * 0.075, Paint()..color = AppTheme.harvest);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "AgriKonek" in the brand colours. [onDark] for use on the green header.
class AgriKonekWordmark extends StatelessWidget {
  const AgriKonekWordmark({super.key, this.fontSize = 28, this.onDark = false});

  final double fontSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: 'Agri',
            style: style.copyWith(color: onDark ? Colors.white : AppTheme.leaf)),
        TextSpan(
            text: 'Konek',
            style: style.copyWith(
                color: onDark ? AppTheme.harvest : AppTheme.soil)),
      ]),
    );
  }
}

/// Calinan's rolling farmland under Mt. Apo, used behind headers.
/// Purely decorative, so screen readers skip it.
class HillsBackdrop extends StatelessWidget {
  const HillsBackdrop({super.key, this.child, this.showSun = true});

  final Widget? child;

  /// Off where header buttons would sit on top of the sun.
  final bool showSun;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: child == null,
      child: CustomPaint(painter: _HillsPainter(showSun), child: child),
    );
  }
}

class _HillsPainter extends CustomPainter {
  _HillsPainter(this.showSun);

  final bool showSun;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.leafDark, AppTheme.leaf],
        ).createShader(rect),
    );

    // Morning sun.
    if (showSun) {
      canvas.drawCircle(Offset(w * 0.82, h * 0.30), math.min(w, h) * 0.12,
          Paint()..color = AppTheme.harvest.withValues(alpha: 0.30));
      canvas.drawCircle(Offset(w * 0.82, h * 0.30), math.min(w, h) * 0.07,
          Paint()..color = AppTheme.harvest.withValues(alpha: 0.55));
    }

    // Mt. Apo on the horizon.
    final mountain = Path()
      ..moveTo(0, h * 0.78)
      ..lineTo(w * 0.18, h * 0.62)
      ..lineTo(w * 0.34, h * 0.40)
      ..quadraticBezierTo(w * 0.38, h * 0.35, w * 0.42, h * 0.40)
      ..lineTo(w * 0.58, h * 0.58)
      ..lineTo(w * 0.72, h * 0.54)
      ..lineTo(w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        mountain, Paint()..color = Colors.white.withValues(alpha: 0.08));

    // Two rows of hills.
    final back = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.55, h * 0.78)
      ..quadraticBezierTo(w * 0.80, h * 0.90, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        back, Paint()..color = AppTheme.leafLight.withValues(alpha: 0.55));

    final front = Path()
      ..moveTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.35, h * 0.76, w * 0.70, h * 0.90)
      ..quadraticBezierTo(w * 0.88, h * 0.97, w, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        front, Paint()..color = AppTheme.leafLight.withValues(alpha: 0.80));
  }

  @override
  bool shouldRepaint(covariant _HillsPainter oldDelegate) =>
      oldDelegate.showSun != showSun;
}
