import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/leave_request.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.fromAttendance(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const StatusBadge(
          label: 'Present',
          color: AppTheme.statusPresent,
          icon: Icons.check_circle_rounded,
        );
      case AttendanceStatus.late:
        return const StatusBadge(
          label: 'Late (>10m)',
          color: AppTheme.statusLate,
          icon: Icons.access_time_rounded,
        );
      case AttendanceStatus.absent:
        return const StatusBadge(
          label: 'Absent',
          color: AppTheme.statusAbsent,
          icon: Icons.cancel_rounded,
        );
      case AttendanceStatus.excused:
        return const StatusBadge(
          label: 'Excused',
          color: AppTheme.statusExcused,
          icon: Icons.verified_user_rounded,
        );
    }
  }

  factory StatusBadge.fromRequestStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.approved:
        return const StatusBadge(
          label: 'Approved',
          color: AppTheme.statusPresent,
          icon: Icons.check_circle_rounded,
        );
      case RequestStatus.pending:
        return const StatusBadge(
          label: 'Pending Review',
          color: AppTheme.statusLate,
          icon: Icons.hourglass_top_rounded,
        );
      case RequestStatus.rejected:
        return const StatusBadge(
          label: 'Rejected',
          color: AppTheme.statusAbsent,
          icon: Icons.block_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
