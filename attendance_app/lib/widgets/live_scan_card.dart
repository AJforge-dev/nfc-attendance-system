import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class LiveScanCard extends StatelessWidget {
  final AttendanceRecord record;
  final UserModel? student;

  const LiveScanCard({
    super.key,
    required this.record,
    this.student,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = student?.name ?? 'Student ${record.studentId}';
    final roll = student?.rollNumber ?? '21CS000';
    final timeStr = record.scanTime != null
        ? DateFormat('hh:mm:ss a').format(record.scanTime!)
        : 'Recorded';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (record.status == AttendanceStatus.present
                    ? AppTheme.statusPresent
                    : AppTheme.statusLate)
                .withOpacity(0.18),
            child: Text(
              name.isNotEmpty ? name[0] : 'S',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: record.status == AttendanceStatus.present
                    ? AppTheme.statusPresent
                    : AppTheme.statusLate,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                  ),
                ),
                Text(
                  '$roll • ${record.deviceId ?? "Reader"} • $timeStr',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge.fromAttendance(record.status),
        ],
      ),
    );
  }
}
