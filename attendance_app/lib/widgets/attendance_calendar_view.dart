import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class AttendanceCalendarView extends StatefulWidget {
  final List<AttendanceRecord> records;

  const AttendanceCalendarView({
    super.key,
    required this.records,
  });

  @override
  State<AttendanceCalendarView> createState() => _AttendanceCalendarViewState();
}

class _AttendanceCalendarViewState extends State<AttendanceCalendarView> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Days of Week Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                return SizedBox(
                  width: 34,
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Calendar Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return const SizedBox();
                }

                final dayNumber = dayOffset + 1;
                final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;

                // Find records on this day
                final dayRecords = widget.records.where((r) {
                  final recDate = r.scanTime ?? r.recordedAt;
                  return recDate.year == date.year &&
                      recDate.month == date.month &&
                      recDate.day == date.day;
                }).toList();

                Color? badgeColor;
                if (dayRecords.isNotEmpty) {
                  if (dayRecords.any((r) => r.status == AttendanceStatus.absent)) {
                    badgeColor = AppTheme.statusAbsent;
                  } else if (dayRecords.any((r) => r.status == AttendanceStatus.late)) {
                    badgeColor = AppTheme.statusLate;
                  } else if (dayRecords.any((r) => r.status == AttendanceStatus.excused)) {
                    badgeColor = AppTheme.statusExcused;
                  } else {
                    badgeColor = AppTheme.statusPresent;
                  }
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = isSelected ? null : date;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppTheme.darkAccent.withOpacity(0.25) : AppTheme.lightAccent.withOpacity(0.15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (badgeColor != null)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: badgeColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              },
            ),

            // If a date is selected, show details
            if (_selectedDate != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedDate = null),
                    child: const Text('Close', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              ...widget.records.where((r) {
                final recDate = r.scanTime ?? r.recordedAt;
                return recDate.year == _selectedDate!.year &&
                    recDate.month == _selectedDate!.month &&
                    recDate.day == _selectedDate!.day;
              }).map((r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r.scanTime != null ? DateFormat('hh:mm a').format(r.scanTime!) : 'Scheduled Class',
                        style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                      ),
                      StatusBadge.fromAttendance(r.status),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
