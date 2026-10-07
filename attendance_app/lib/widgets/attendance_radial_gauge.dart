import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AttendanceRadialGauge extends StatefulWidget {
  final double percentage;
  final int attended;
  final int total;
  final int lates;
  final double threshold;
  final double size;

  const AttendanceRadialGauge({
    super.key,
    required this.percentage,
    required this.attended,
    required this.total,
    required this.lates,
    this.threshold = 75.0,
    this.size = 200,
  });

  @override
  State<AttendanceRadialGauge> createState() => _AttendanceRadialGaugeState();
}

class _AttendanceRadialGaugeState extends State<AttendanceRadialGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AttendanceRadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: oldWidget.percentage,
        end: widget.percentage,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForPercentage(double pct) {
    if (pct >= 80.0) return AppTheme.statusPresent;
    if (pct >= widget.threshold) return AppTheme.statusLate;
    return AppTheme.statusAbsent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentPct = _animation.value;
        final color = _getColorForPercentage(currentPct);
        final isBelowThreshold = currentPct < widget.threshold;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _GaugePainter(
                    percentage: currentPct,
                    gaugeColor: color,
                    trackColor: isDark ? const Color(0xFF23302B) : const Color(0xFFE2EBE7),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: (widget.size * 0.2).clamp(24.0, 42.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'OVERALL ATTENDANCE',
                          style: TextStyle(
                            fontSize: (widget.size * 0.05).clamp(8.0, 10.0),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isBelowThreshold ? 'Below 75% Limit!' : 'Eligible for Exams',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statChip(
                    context,
                    label: 'Effective Attended',
                    value: '${widget.attended} / ${widget.total}',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.statusPresent,
                  ),
                  const SizedBox(width: 12),
                  _statChip(
                    context,
                    label: 'Lates Logged',
                    value: '${widget.lates} (3 lates = 1 abs)',
                    icon: Icons.access_time,
                    color: AppTheme.statusLate,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color gaugeColor;
  final Color trackColor;

  _GaugePainter({
    required this.percentage,
    required this.gaugeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    const startAngle = 0.75 * math.pi; // 135 degrees
    const totalSweep = 1.5 * math.pi;  // 270 degrees

    // Track Paint
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Progress Arc Paint
    final progressSweep = (percentage.clamp(0.0, 100.0) / 100.0) * totalSweep;
    final progressPaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    if (progressSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.gaugeColor != gaugeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
