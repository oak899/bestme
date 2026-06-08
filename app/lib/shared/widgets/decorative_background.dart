import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DecorativeBackground extends StatelessWidget {
  const DecorativeBackground({super.key, this.child, this.intensity = 0.08});
  final Widget? child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -40,
          child: _Blob(
            size: 220,
            color: AppColors.blob1.withValues(alpha: intensity),
          ),
        ),
        Positioned(
          top: 120,
          left: -60,
          child: _Blob(
            size: 180,
            color: AppColors.blob2.withValues(alpha: intensity * 0.8),
          ),
        ),
        Positioned(
          top: 300,
          right: -30,
          child: _Blob(
            size: 140,
            color: AppColors.blob3.withValues(alpha: intensity * 0.6),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 18, -7,
        ]),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class HeroDecoration extends StatelessWidget {
  const HeroDecoration({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          child,
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 60,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmojiIllustration extends StatelessWidget {
  const EmojiIllustration({
    super.key,
    required this.emoji,
    this.size = 80,
    this.backgroundColor,
  });
  final String emoji;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary.withValues(alpha: 0.08);
    return Container(
      width: size + 24,
      height: size + 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size),
        ),
      ),
    );
  }
}

class DottedPattern extends StatelessWidget {
  const DottedPattern({super.key, this.color, this.spacing = 20});
  final Color? color;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final dotColor = color ?? AppColors.textMuted.withValues(alpha: 0.15);
    return CustomPaint(
      size: Size.infinite,
      painter: _DotPainter(dotColor: dotColor, spacing: spacing),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter({required this.dotColor, required this.spacing});
  final Color dotColor;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GradientOrb extends StatelessWidget {
  const GradientOrb({
    super.key,
    required this.size,
    required this.colors,
    this.blur = 40,
  });
  final double size;
  final List<Color> colors;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
        ),
      ),
      child: BackdropFilter(
        filter: const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 18, -7,
        ]),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class WaveDecoration extends StatelessWidget {
  const WaveDecoration({super.key, this.color, this.height = 60});
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final waveColor = color ?? AppColors.primary.withValues(alpha: 0.06);
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [waveColor, waveColor.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.4,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Icon(icon, size: size * 0.45, color: color),
    );
  }
}

class StatusRing extends StatelessWidget {
  const StatusRing({
    super.key,
    required this.progress,
    required this.size,
    this.strokeWidth = 6,
    this.color,
    this.backgroundColor,
  });
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    final bg = backgroundColor ?? activeColor.withValues(alpha: 0.12);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          activeColor: activeColor,
          backgroundColor: bg,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.activeColor,
    required this.backgroundColor,
  });
  final double progress;
  final double strokeWidth;
  final Color activeColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [activeColor, activeColor.withValues(alpha: 0.7)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
