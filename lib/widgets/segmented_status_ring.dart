import 'dart:math';
import 'package:flutter/material.dart';

class SegmentedStatusRing extends StatelessWidget {
  final int segmentCount;
  final List<bool> viewedSegments;
  final double radius;
  final double strokeWidth;
  final Color unviewedColor;
  final Color viewedColor;

  const SegmentedStatusRing({
    super.key,
    required this.segmentCount,
    required this.viewedSegments,
    this.radius = 30.0,
    this.strokeWidth = 3.0,
    this.unviewedColor = Colors.blue,
    this.viewedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _SegmentedRingPainter(
        segmentCount: segmentCount,
        viewedSegments: viewedSegments,
        strokeWidth: strokeWidth,
        unviewedColor: unviewedColor,
        viewedColor: viewedColor,
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final int segmentCount;
  final List<bool> viewedSegments;
  final double strokeWidth;
  final Color unviewedColor;
  final Color viewedColor;

  _SegmentedRingPainter({
    required this.segmentCount,
    required this.viewedSegments,
    required this.strokeWidth,
    required this.unviewedColor,
    required this.viewedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final sweepAngle = (2 * pi) / segmentCount;
    final gap = sweepAngle * 0.1; // 10% gap between segments

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = -pi / 2 + i * sweepAngle;
      final paint = Paint()
        ..color = viewedSegments[i] ? viewedColor : unviewedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
