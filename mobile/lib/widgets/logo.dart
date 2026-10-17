import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
        ),
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = size.width * 0.06
          ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.16, y),
      Offset(size.width * 0.84, y),
      line,
    );
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.18, y), size.width * 0.045, dot);
    canvas.drawCircle(Offset(size.width * 0.82, y), size.width * 0.045, dot);
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, y),
        width: size.width * 0.38,
        height: size.height * 0.25,
      ),
      Radius.circular(size.height),
    );
    canvas.drawRRect(pill, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(size.width / 2, y),
      size.width * 0.065,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width / 2, y),
            radius: size.width * 0.08,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'OneLine', style: style),
          TextSpan(
            text: 'Planner',
            style: style?.copyWith(color: const Color(0xFF8B5CF6)),
          ),
        ],
      ),
    );
  }
}
