import 'dart:math';
import 'package:flutter/material.dart';
import '../models/buddy_expression.dart';

class BuddyFaceWidget extends StatefulWidget {
  final BuddyExpression expression;
  final BuddyMode mode;
  final bool isTalking;
  final bool isListening;
  final String statusText;
  final VoidCallback? onTap;

  const BuddyFaceWidget({
    super.key,
    required this.expression,
    required this.mode,
    this.isTalking = false,
    this.isListening = false,
    required this.statusText,
    this.onTap,
  });

  @override
  State<BuddyFaceWidget> createState() => _BuddyFaceWidgetState();
}

class _BuddyFaceWidgetState extends State<BuddyFaceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.mode == BuddyMode.study
                    ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                    : [const Color(0xFF111827), const Color(0xFF1F1D36)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.mode == BuddyMode.study
                    ? const Color(0xFF00E5FF).withOpacity(0.4)
                    : const Color(0xFFFF4081).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.mode == BuddyMode.study
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFFFF4081))
                      .withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Screen Bezel with Robot Ears/Antenna Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mode Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.mode == BuddyMode.study
                            ? const Color(0xFF00E5FF).withOpacity(0.15)
                            : const Color(0xFFFF4081).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.mode == BuddyMode.study
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFFFF4081),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.mode == BuddyMode.study
                                ? Icons.psychology_rounded
                                : Icons.favorite_rounded,
                            size: 14,
                            color: widget.mode == BuddyMode.study
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFFFF4081),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.mode == BuddyMode.study
                                ? "STUDY BUDDY"
                                : "CLOSE FRIEND",
                            style: TextStyle(
                              color: widget.mode == BuddyMode.study
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFFFF4081),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expression Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.expression.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // OLED SCREEN / FACE DISPLAY
                Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF070A10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF1E293B), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // CRT Scanline effect
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ScanlinePainter(),
                          ),
                        ),

                        // Animated Robot Face Custom Paint
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: CustomPaint(
                            size: const Size(180, 80),
                            painter: _RobotFacePainter(
                              expression: widget.expression,
                              mode: widget.mode,
                              isTalking: widget.isTalking,
                              isListening: widget.isListening,
                              animValue: _animController.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom Status Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.statusText.contains('Offline')
                            ? Colors.orange
                            : const Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (widget.statusText.contains('Offline')
                                    ? Colors.orange
                                    : const Color(0xFF00E5FF))
                                .withOpacity(0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.statusText,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RobotFacePainter extends CustomPainter {
  final BuddyExpression expression;
  final BuddyMode mode;
  final bool isTalking;
  final bool isListening;
  final double animValue;

  _RobotFacePainter({
    required this.expression,
    required this.mode,
    required this.isTalking,
    required this.isListening,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final eyeColor = mode == BuddyMode.study
        ? const Color(0xFF00F2FE)
        : const Color(0xFFFF4081);

    final eyeGlow = Paint()
      ..color = eyeColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    final leftCenter = Offset(size.width * 0.32, size.height * 0.45);
    final rightCenter = Offset(size.width * 0.68, size.height * 0.45);

    // DRAW EYES BASED ON EXPRESSION
    switch (expression) {
      case BuddyExpression.happy:
        _drawHappyEye(canvas, leftCenter, eyePaint, eyeGlow);
        _drawHappyEye(canvas, rightCenter, eyePaint, eyeGlow);
        _drawSmile(canvas, size, eyePaint);
        break;

      case BuddyExpression.excited:
        _drawStarEye(canvas, leftCenter, eyePaint, eyeGlow);
        _drawStarEye(canvas, rightCenter, eyePaint, eyeGlow);
        _drawWideSmile(canvas, size, eyePaint);
        break;

      case BuddyExpression.studyFocused:
        _drawFocusEye(canvas, leftCenter, eyePaint, eyeGlow);
        _drawFocusEye(canvas, rightCenter, eyePaint, eyeGlow);
        _drawVisorBridge(canvas, leftCenter, rightCenter, eyePaint);
        break;

      case BuddyExpression.thinking:
        _drawThinkingEye(canvas, leftCenter, eyePaint, eyeGlow, animValue);
        _drawThinkingEye(canvas, rightCenter, eyePaint, eyeGlow, animValue);
        break;

      case BuddyExpression.sleepy:
        _drawSleepyEye(canvas, leftCenter, eyePaint);
        _drawSleepyEye(canvas, rightCenter, eyePaint);
        _drawZzz(canvas, rightCenter, eyePaint);
        break;

      case BuddyExpression.surprised:
        _drawSurpriseEye(canvas, leftCenter, eyePaint, eyeGlow);
        _drawSurpriseEye(canvas, rightCenter, eyePaint, eyeGlow);
        _drawSurpriseMouth(canvas, size, eyePaint);
        break;

      case BuddyExpression.cool:
        _drawSunglasses(canvas, leftCenter, rightCenter, eyePaint, eyeGlow);
        _drawSmirk(canvas, size, eyePaint);
        break;

      case BuddyExpression.listening:
        _drawListeningWaves(canvas, leftCenter, rightCenter, eyePaint, animValue);
        break;

      case BuddyExpression.talking:
        _drawNormalEye(canvas, leftCenter, eyePaint, eyeGlow);
        _drawNormalEye(canvas, rightCenter, eyePaint, eyeGlow);
        _drawTalkingMouth(canvas, size, eyePaint, animValue);
        break;
    }

    // If talking is active regardless of expression, draw talking audio wave
    if (isTalking && expression != BuddyExpression.talking) {
      _drawTalkingMouth(canvas, size, eyePaint, animValue);
    }
  }

  void _drawNormalEye(Canvas canvas, Offset center, Paint paint, Paint glow) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 26, height: 32),
        const Radius.circular(8),
      ),
      glow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 24, height: 30),
        const Radius.circular(7),
      ),
      paint,
    );
    // Reflection pupil
    final reflex = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(Offset(center.dx - 4, center.dy - 6), 3, reflex);
  }

  void _drawHappyEye(Canvas canvas, Offset center, Paint paint, Paint glow) {
    final path = Path()
      ..moveTo(center.dx - 14, center.dy + 4)
      ..quadraticBezierTo(center.dx, center.dy - 16, center.dx + 14, center.dy + 4);

    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, linePaint);
  }

  void _drawStarEye(Canvas canvas, Offset center, Paint paint, Paint glow) {
    final size = 16.0;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi) / 5 - pi / 2;
      final x = center.dx + size * cos(angle);
      final y = center.dy + size * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  void _drawFocusEye(Canvas canvas, Offset center, Paint paint, Paint glow) {
    // Rectangular smart visor eye
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 30, height: 16),
      glow,
    );
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 28, height: 14),
      paint,
    );
    // Inner scanline
    final linePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx + 12, center.dy),
      linePaint,
    );
  }

  void _drawVisorBridge(Canvas canvas, Offset left, Offset right, Paint paint) {
    final bridgePaint = Paint()
      ..color = paint.color.withOpacity(0.8)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(left.dx + 14, left.dy),
      Offset(right.dx - 14, right.dy),
      bridgePaint,
    );
  }

  void _drawThinkingEye(Canvas canvas, Offset center, Paint paint, Paint glow, double anim) {
    // Eye looking up and right
    final offsetCenter = Offset(center.dx + 4, center.dy - 6);
    canvas.drawCircle(offsetCenter, 12, glow);
    canvas.drawCircle(offsetCenter, 10, paint);
  }

  void _drawSleepyEye(Canvas canvas, Offset center, Paint paint) {
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - 12, center.dy + 4),
      Offset(center.dx + 12, center.dy + 4),
      linePaint,
    );
  }

  void _drawZzz(Canvas canvas, Offset center, Paint paint) {
    final zPaint = TextPainter(
      text: TextSpan(
        text: 'Zzz',
        style: TextStyle(
          color: paint.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    zPaint.layout();
    zPaint.paint(canvas, Offset(center.dx + 16, center.dy - 20));
  }

  void _drawSurpriseEye(Canvas canvas, Offset center, Paint paint, Paint glow) {
    canvas.drawCircle(center, 16, glow);
    canvas.drawCircle(center, 14, paint);
    final pupil = Paint()..color = const Color(0xFF070A10);
    canvas.drawCircle(center, 7, pupil);
  }

  void _drawSunglasses(Canvas canvas, Offset left, Offset right, Paint paint, Paint glow) {
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: left, width: 36, height: 22),
      const Radius.circular(6),
    );
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: right, width: 36, height: 22),
      const Radius.circular(6),
    );

    final glassPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(leftRect, glassPaint);
    canvas.drawRRect(rightRect, glassPaint);
    canvas.drawRRect(leftRect, border);
    canvas.drawRRect(rightRect, border);

    // Bridge
    canvas.drawLine(
      Offset(left.dx + 18, left.dy),
      Offset(right.dx - 18, right.dy),
      border,
    );
  }

  void _drawListeningWaves(Canvas canvas, Offset left, Offset right, Paint paint, double anim) {
    final wavePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final radius = 8.0 + (i * 6.0) + (anim * 4.0);
      canvas.drawCircle(left, radius, wavePaint..color = paint.color.withOpacity(1.0 - (i * 0.25)));
      canvas.drawCircle(right, radius, wavePaint..color = paint.color.withOpacity(1.0 - (i * 0.25)));
    }
  }

  void _drawSmile(Canvas canvas, Size size, Paint paint) {
    final smilePath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.84, size.width * 0.56, size.height * 0.72);

    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(smilePath, linePaint);
  }

  void _drawWideSmile(Canvas canvas, Size size, Paint paint) {
    final smilePath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.70)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.88, size.width * 0.58, size.height * 0.70)
      ..close();
    canvas.drawPath(smilePath, paint);
  }

  void _drawTalkingMouth(Canvas canvas, Size size, Paint paint, double anim) {
    final mouthWidth = 24.0 + (anim * 8.0);
    final mouthHeight = 6.0 + (anim * 10.0);
    final mouthRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.76),
        width: mouthWidth,
        height: mouthHeight,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(mouthRect, paint);
  }

  void _drawSmirk(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width * 0.46, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.54, size.height * 0.76, size.width * 0.58, size.height * 0.68);
    final linePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);
  }

  void _drawSurpriseMouth(Canvas canvas, Size size, Paint paint) {
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.74), 7, paint);
  }

  @override
  bool shouldRepaint(covariant _RobotFacePainter oldDelegate) => true;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
