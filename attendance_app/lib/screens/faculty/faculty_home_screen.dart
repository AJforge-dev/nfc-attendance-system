import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_record.dart';
import '../../models/user.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/live_scan_card.dart';
import '../../widgets/nfc_scan_simulator_dialog.dart';
import 'marks_entry_screen.dart';

class FacultyHomeScreen extends StatelessWidget {
  const FacultyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final user = provider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final session = provider.activeSession ?? provider.sessions.first;
    final sessionRecords = provider.records.where((r) => r.sessionId == session.id).toList();

    final presentCount = sessionRecords.where((r) => r.status == AttendanceStatus.present).length;
    final lateCount = sessionRecords.where((r) => r.status == AttendanceStatus.late).length;
    final students = provider.users.where((u) => u.role == UserRole.student).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Faculty Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Faculty Classroom Monitor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                      ),
                    ),
                    Text(
                      '${user.name} • ${user.designation ?? user.department}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const MarksEntryDialog(),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Enter Marks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Classroom Session Banner
            Card(
              color: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusPresent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sensors_rounded, size: 14, color: AppTheme.statusPresent),
                              SizedBox(width: 4),
                              Text(
                                'LIVE CLASS IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.statusPresent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${DateFormat('hh:mm a').format(session.startTime)} - ${DateFormat('hh:mm a').format(session.endTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${session.subjectCode}: ${session.subjectName}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Room: ${session.room} • Faculty: ${session.facultyName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                    const Divider(height: 24),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricItem(
                          title: 'Scanned',
                          value: '${sessionRecords.length} / ${students.length}',
                          color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                        ),
                        _metricItem(
                          title: 'On-Time (Present)',
                          value: '$presentCount',
                          color: AppTheme.statusPresent,
                        ),
                        _metricItem(
                          title: 'Late Arrivals',
                          value: '$lateCount',
                          color: AppTheme.statusLate,
                        ),
                        _metricItem(
                          title: 'Unscanned',
                          value: '${(students.length - sessionRecords.length).clamp(0, students.length)}',
                          color: AppTheme.statusAbsent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Live Incoming Scan Feed Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REAL-TIME NFC SCAN FEED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const NfcScanSimulatorDialog(),
                    );
                  },
                  icon: const Icon(Icons.nfc, size: 16),
                  label: const Text('Simulate Tap', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (sessionRecords.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.wifi_tethering_rounded, size: 36, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for student card taps at ESP32 reader (${session.room})...',
                          style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...sessionRecords.map((r) {
                final st = provider.users.firstWhere(
                  (u) => u.id == r.studentId,
                  orElse: () => UserModel(id: '', orgId: '', name: 'Student', email: '', role: UserRole.student, department: ''),
                );
                return LiveScanCard(record: r, student: st);
              }),

            const SizedBox(height: 20),

            // Enrolled Students Overview
            Text(
              'ENROLLED CLASS STUDENTS & OVERALL ATTENDANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
            const SizedBox(height: 8),
            ...students.map((s) {
              final sStats = provider.getStudentAttendanceStats(s.id);
              final double sPct = (sStats['percentage'] as num).toDouble();
              final bool isScannedNow = sessionRecords.any((r) => r.studentId == s.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: isScannedNow
                        ? AppTheme.statusPresent.withOpacity(0.2)
                        : (isDark ? AppTheme.darkSoft : AppTheme.lightSoft),
                    child: Icon(
                      isScannedNow ? Icons.check : Icons.person_outline,
                      color: isScannedNow ? AppTheme.statusPresent : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
                      size: 18,
                    ),
                  ),
                  title: Text(
                    '${s.name} (${s.rollNumber ?? "N/A"})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Tag: ${s.tagUid ?? "None"} • Overall Attendance: $sPct%',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                  ),
                  trailing: Text(
                    '$sPct%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: sPct >= 75 ? AppTheme.statusPresent : AppTheme.statusAbsent,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _metricItem({required String title, required String value, required Color color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
