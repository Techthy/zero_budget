import 'package:flutter/material.dart';

import '../money.dart';

/// A plant growing out of a coin pot, like the app's logo, that is as grown
/// as [growth], from 0 (a seed) to 1 (fully grown, with sparkles).
///
/// Changes to [growth] are animated.
class SavingsPlant extends StatelessWidget {
  const SavingsPlant({super.key, required this.growth, this.size = 32});

  final double growth;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: growth),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, growth, _) => CustomPaint(
        size: Size.square(size),
        painter: _PlantPainter(
          growth.clamp(0.0, 1.0),
          coinSymbol: currency.coinSymbol,
        ),
      ),
    );
  }
}

/// A leaf on the stem: where it sits along the stem (0 at the soil, 1 at the
/// top), its angle (0 points right, negative up), its length, and the growth
/// at which it starts to unfold.
typedef _Leaf = ({double at, double angle, double length, double from});

// Drawn on a 100 by 100 canvas, scaled to the size.
class _PlantPainter extends CustomPainter {
  _PlantPainter(this.growth, {required this.coinSymbol});

  final double growth;

  /// On the coin's face, like the € in the logo.
  final String coinSymbol;

  static const _gold = Color(0xFFF2B93B);
  static const _goldLight = Color(0xFFFAD772);
  static const _goldDark = Color(0xFFB8781C);
  static const _soil = Color(0xFF6D4C2F);
  static const _seed = Color(0xFF8D6E3F);
  static const _stem = Color(0xFF6DAA3C);
  static const _leaf = Color(0xFFA5D46A);
  static const _leafShade = Color(0xFF7CB342);
  static const _leafDark = Color(0xFF558B2F);

  static const _soilY = 64.0;
  static const _fullStemLength = 40.0;

  /// Leaves unfold one after another; the last ones at the top.
  static const List<_Leaf> _leaves = [
    (at: 0.35, angle: -2.75, length: 19, from: 0.1),
    (at: 0.6, angle: -0.4, length: 21, from: 0.3),
    (at: 1, angle: -2.3, length: 26, from: 0.5),
    (at: 1, angle: -0.75, length: 28, from: 0.7),
  ];

  /// How long a leaf takes to unfold, as a share of the growth.
  static const _unfold = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    // The stem grows over the first 60%, then only the leaves.
    final stemLength =
        _fullStemLength * Curves.easeOut.transform((growth / 0.6).clamp(0, 1));
    final stemTop = _soilY - stemLength;
    // Bends a little to the left on its way up.
    Offset stemAt(double t) => Offset(
      50 - 8 * t * (1 - t) * (stemLength / _fullStemLength),
      _soilY - stemLength * t,
    );

    if (growth < 0.05) {
      canvas.drawOval(
        const Rect.fromLTRB(46, 58, 54, 63),
        Paint()..color = _seed,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(50, _soilY + 2)
          ..quadraticBezierTo(
            50 - 4 * (stemLength / _fullStemLength),
            (_soilY + stemTop) / 2,
            50,
            stemTop,
          ),
        Paint()
          ..color = _stem
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final leaf in _leaves) {
      final unfolded = ((growth - leaf.from) / _unfold).clamp(0.0, 1.0);
      if (unfolded == 0) continue;
      _paintLeaf(
        canvas,
        stemAt(leaf.at),
        leaf.angle,
        leaf.length * Curves.easeOutBack.transform(unfolded),
      );
    }

    if (growth >= 1) _paintSparkles(canvas);
    _paintPot(canvas);
  }

  void _paintLeaf(Canvas canvas, Offset base, double angle, double length) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    // Broad and pointed, lighter on the upper half.
    final width = length * 0.38;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(length * 0.25, -width, length * 0.75, -width * 0.8, length, 0)
        ..close(),
      Paint()..color = _leaf,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(length * 0.25, width, length * 0.75, width * 0.8, length, 0)
        ..close(),
      Paint()..color = _leafShade,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(length * 0.8, 0),
      Paint()
        ..color = _leafDark
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintSparkles(Canvas canvas) {
    final paint = Paint()
      ..color = _leaf
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in const [
      (Offset(12, 44), Offset(18, 49)),
      (Offset(8, 57), Offset(15, 58)),
      (Offset(88, 42), Offset(83, 48)),
      (Offset(92, 55), Offset(85, 57)),
    ]) {
      canvas.drawLine(from, to, paint);
    }
  }

  void _paintPot(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTRB(30, 92, 70, 98),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      Path()
        ..moveTo(28, 64)
        ..lineTo(72, 64)
        ..cubicTo(76, 79, 68, 95, 50, 95)
        ..cubicTo(32, 95, 24, 79, 28, 64)
        ..close(),
      Paint()..color = _gold,
    );
    // The coin's face, with the currency's sign.
    const face = Offset(51, 80);
    canvas.drawCircle(face, 11, Paint()..color = _goldLight);
    canvas.drawCircle(
      face,
      11,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final sign = TextPainter(
      text: TextSpan(
        text: coinSymbol,
        style: const TextStyle(
          color: _goldDark,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sign.paint(canvas, face - Offset(sign.width / 2, sign.height / 2));
    sign.dispose();
    // The rim, with soil inside.
    canvas.drawOval(
      const Rect.fromLTRB(26, 59.5, 74, 68.5),
      Paint()..color = _goldLight,
    );
    canvas.drawOval(
      const Rect.fromLTRB(31, 61.5, 69, 66.5),
      Paint()..color = _soil,
    );
  }

  @override
  bool shouldRepaint(_PlantPainter oldDelegate) =>
      oldDelegate.growth != growth || oldDelegate.coinSymbol != coinSymbol;
}
