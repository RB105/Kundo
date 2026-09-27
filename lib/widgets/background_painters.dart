import 'dart:math';

import 'package:flutter/material.dart';

import '../models/list_background.dart';

/// Built-in backgrounds are painted, not shipped as images: they are drawn from
/// the list's own theme color, weigh nothing in the bundle and stay sharp at
/// any size, from a 375pt phone to a full-screen desktop window.
CustomPainter backgroundPainterFor(BackgroundStyle style, Color color) =>
    switch (style) {
      BackgroundStyle.aurora => _AuroraPainter(color),
      BackgroundStyle.dunes => _DunesPainter(color),
      BackgroundStyle.peaks => _PeaksPainter(color),
      BackgroundStyle.night => _NightPainter(color),
      BackgroundStyle.bokeh => _BokehPainter(color),
    };

Color _shift(Color color, {double lightness = 0, double hue = 0}) {
  final HSLColor hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
      .withHue((hsl.hue + hue) % 360)
      .toColor();
}

void _radialGlow(Canvas canvas, Offset center, double radius, Color color) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius)),
  );
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _shift(color, lightness: -0.24),
            color,
            _shift(color, lightness: -0.14, hue: -22),
          ],
        ).createShader(rect),
    );

    // Glow radii follow the short side, so the shapes keep their proportions
    // whether the surface is a tall phone or a wide window.
    final double unit = size.shortestSide;
    _radialGlow(canvas, Offset(size.width * 0.20, size.height * 0.18),
        unit * 0.62, _shift(color, lightness: 0.12, hue: 26).withValues(alpha: 0.55));
    _radialGlow(canvas, Offset(size.width * 0.88, size.height * 0.52),
        unit * 0.72, _shift(color, lightness: 0.18, hue: -30).withValues(alpha: 0.40));
    _radialGlow(canvas, Offset(size.width * 0.45, size.height * 0.98),
        unit * 0.60, _shift(color, lightness: -0.26).withValues(alpha: 0.70));
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => oldDelegate.color != color;
}

class _DunesPainter extends CustomPainter {
  const _DunesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_shift(color, lightness: 0.16, hue: 12), color],
        ).createShader(rect),
    );

    _wave(canvas, size, 0.58, 0.10, _shift(color, lightness: -0.08));
    _wave(canvas, size, 0.72, -0.08, _shift(color, lightness: -0.16));
    _wave(canvas, size, 0.86, 0.06, _shift(color, lightness: -0.24));
  }

  void _wave(Canvas canvas, Size size, double top, double curve, Color color) {
    final Path path = Path()
      ..moveTo(0, size.height * top)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * (top + curve),
        size.width,
        size.height * (top - curve * 0.6),
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DunesPainter oldDelegate) => oldDelegate.color != color;
}

class _PeaksPainter extends CustomPainter {
  const _PeaksPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _shift(color, lightness: 0.20, hue: -14),
            _shift(color, lightness: -0.04),
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.20),
      size.shortestSide * 0.09,
      Paint()..color = _shift(color, lightness: 0.34).withValues(alpha: 0.85),
    );

    _ridge(canvas, size, <double>[0.72, 0.50, 0.74, 0.56, 0.78],
        _shift(color, lightness: -0.16));
    _ridge(canvas, size, <double>[0.88, 0.64, 0.88, 0.74, 0.92],
        _shift(color, lightness: -0.26));
  }

  /// Ridge heights are fractions of the height, so the silhouette scales with
  /// the surface instead of being cropped off on a short window.
  void _ridge(Canvas canvas, Size size, List<double> heights, Color color) {
    final Path path = Path()..moveTo(0, size.height * heights[0]);
    for (int i = 1; i < heights.length; i++) {
      path.lineTo(size.width * (i / (heights.length - 1)), size.height * heights[i]);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PeaksPainter oldDelegate) => oldDelegate.color != color;
}

class _NightPainter extends CustomPainter {
  const _NightPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _shift(color, lightness: -0.34),
            _shift(color, lightness: -0.12, hue: 18),
          ],
        ).createShader(rect),
    );

    // A fixed seed keeps the sky identical between repaints and window resizes.
    final Random random = Random(11);
    for (int i = 0; i < 70; i++) {
      final Offset star = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.78,
      );
      canvas.drawCircle(
        star,
        0.6 + random.nextDouble() * 1.5,
        Paint()
          ..color =
              Colors.white.withValues(alpha: 0.25 + random.nextDouble() * 0.55),
      );
    }

    _radialGlow(
      canvas,
      Offset(size.width * 0.5, size.height * 1.06),
      size.width * 0.8,
      _shift(color, lightness: 0.16).withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_NightPainter oldDelegate) => oldDelegate.color != color;
}

class _BokehPainter extends CustomPainter {
  const _BokehPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_shift(color, lightness: -0.18, hue: -16), color],
        ).createShader(rect),
    );

    final Random random = Random(23);
    final double unit = size.shortestSide;
    for (int i = 0; i < 16; i++) {
      final Offset center = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      _radialGlow(
        canvas,
        center,
        unit * (0.06 + random.nextDouble() * 0.16),
        Colors.white.withValues(alpha: 0.05 + random.nextDouble() * 0.11),
      );
    }
  }

  @override
  bool shouldRepaint(_BokehPainter oldDelegate) => oldDelegate.color != color;
}
