import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/budget_theme.dart';

/// Faint leafy branches behind a screen's content, growing in from the
/// top-right and bottom-left corners. They stay put while the content scrolls
/// and never take taps.
class LeafBackground extends StatelessWidget {
  const LeafBackground({super.key, required this.child, this.expand = true});

  final Widget child;

  /// Whether it fills all the space it gets, like a screen, or is only as
  /// big as [child], like a sheet sized to its content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Quiet enough that text drawn over a leaf stays easy to read.
    final painter = _LeafPainter(
      leaf: c.sprout.withValues(alpha: dark ? 0.11 : 0.16),
      shade: c.sproutStrong.withValues(alpha: dark ? 0.09 : 0.13),
      vein: c.sproutStrong.withValues(alpha: dark ? 0.13 : 0.18),
    );
    return Stack(
      fit: expand ? StackFit.expand : StackFit.loose,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: painter)),
          ),
        ),
        child,
      ],
    );
  }
}

/// A branch drawn as a quadratic curve, with leaves along it.
typedef _Branch = ({
  Offset Function(Size) start,
  Offset Function(Size) control,
  Offset Function(Size) end,
  // Where each leaf sits along the branch (0 at the start, 1 at the tip),
  // which side it grows to (1 or -1), and its length.
  List<({double at, double side, double length})> leaves,
});

class _LeafPainter extends CustomPainter {
  _LeafPainter({required this.leaf, required this.shade, required this.vein});

  final Color leaf;
  final Color shade;
  final Color vein;

  static final List<_Branch> _branches = [
    // Top right, reaching down and inward.
    (
      start: (s) => Offset(s.width + 12, 24),
      control: (s) => Offset(s.width - 70, 40),
      end: (s) => Offset(s.width - 150, 170),
      leaves: const [
        (at: 0.08, side: 1, length: 44),
        (at: 0.24, side: -1, length: 50),
        (at: 0.42, side: 1, length: 54),
        (at: 0.6, side: -1, length: 46),
        (at: 0.78, side: 1, length: 40),
        (at: 1, side: 0, length: 36),
      ],
    ),
    // Bottom left, reaching up and inward.
    (
      start: (s) => Offset(-12, s.height - 30),
      control: (s) => Offset(80, s.height - 50),
      end: (s) => Offset(140, s.height - 200),
      leaves: const [
        (at: 0.1, side: -1, length: 46),
        (at: 0.27, side: 1, length: 52),
        (at: 0.45, side: -1, length: 56),
        (at: 0.64, side: 1, length: 46),
        (at: 0.82, side: -1, length: 38),
        (at: 1, side: 0, length: 34),
      ],
    ),
  ];

  /// Single leaves drifting on their own: position as a share of the size,
  /// angle, and length.
  static const List<({double x, double y, double angle, double length})>
  _loose = [
    (x: 0.9, y: 0.5, angle: -2.2, length: 30),
    (x: 0.06, y: 0.3, angle: -0.5, length: 26),
    (x: 0.55, y: 0.82, angle: -2.7, length: 22),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Slightly larger leaves on wide screens, never tiny on small ones.
    final scale = (size.width / 400).clamp(0.85, 1.4);

    final stem = Paint()
      ..color = vein
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;

    for (final branch in _branches) {
      final p0 = branch.start(size);
      final p1 = branch.control(size);
      final p2 = branch.end(size);
      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy),
        stem,
      );
      for (final l in branch.leaves) {
        final t = l.at;
        final point = _bezier(p0, p1, p2, t);
        final tangent = (p1 - p0) * (2 * (1 - t)) + (p2 - p1) * (2 * t);
        // Side leaves angle off forward from the branch; the tip carries on.
        final angle = tangent.direction + l.side * 0.85;
        _paintLeaf(canvas, point, angle, l.length * scale);
      }
    }

    for (final l in _loose) {
      _paintLeaf(
        canvas,
        Offset(size.width * l.x, size.height * l.y),
        l.angle,
        l.length * scale,
      );
    }
  }

  static Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  // The same shape as the savings plant's leaves: broad and pointed, one half
  // a shade darker, with a vein down the middle.
  void _paintLeaf(Canvas canvas, Offset base, double angle, double length) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final width = length * 0.38;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(length * 0.25, -width, length * 0.75, -width * 0.8, length, 0)
        ..close(),
      Paint()..color = leaf,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(length * 0.25, width, length * 0.75, width * 0.8, length, 0)
        ..close(),
      Paint()..color = shade,
    );
    canvas.drawLine(
      Offset.zero,
      Offset(length * 0.8, 0),
      Paint()
        ..color = vein
        ..strokeWidth = math.max(1, length / 30)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LeafPainter old) =>
      old.leaf != leaf || old.shade != shade || old.vein != vein;
}
