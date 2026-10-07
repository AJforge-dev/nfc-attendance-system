import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/attendance_radial_gauge.dart';
import '../../widgets/attendance_calendar_view.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/ai_chatbot_sheet.dart';
import 'apply_leave_dialog.dart';
import 'apply_condonation_dialog.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // Category indices:
  // 0: Attendance Overview
  // 1: Monthly Attendance Checks
  // 2: Subject Breakdown
  // 3: Leave & On-Duty (OD)
  int _selectedCategoryIndex = 0;

  final List<({String title, IconData icon})> _categories = [
    (title: 'Attendance', icon: Icons.donut_large_rounded),
    (title: 'Monthly Checks', icon: Icons.calendar_month_rounded),
    (title: 'Subjects', icon: Icons.menu_book_rounded),
    (title: 'Leave & OD', icon: Icons.event_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final user = provider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stats = provider.getStudentAttendanceStats(user.id);
    final double pct = (stats['percentage'] as num).toDouble();
    final int attended = stats['present'] as int;
    final int lates = stats['late'] as int;
    final int total = stats['effectiveTotal'] as int;
    final int latesAsAbs = stats['latesAsAbsence'] as int;
    final int excused = stats['excused'] as int;

    final studentRecords = provider.records.where((r) => r.studentId == user.id).toList();
    final studentLeaves = provider.leaveRequests.where((l) => l.studentId == user.id).toList();
    final subjectStats = provider.getSubjectWiseAttendance(user.id);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Welcome Header
            _buildTopWelcome(context, user, pct, isDark),

            // Critical Attendance Alert Banner (if < 75%)
            if (pct < 75.0) _buildCriticalAlert(context, pct, isDark),

            // Category Navigation Bar
            _buildCategoryNavBar(isDark),

            const SizedBox(height: 6),

            // Main Split Area: Main Content on the Left + Category Buttons on the Right Side
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left / Main Content Container
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 8, 80),
                      child: _buildSelectedCategoryContent(
                        context,
                        provider,
                        pct,
                        attended,
                        total,
                        lates,
                        latesAsAbs,
                        excused,
                        studentRecords,
                        studentLeaves,
                        subjectStats,
                        isDark,
                      ),
                    ),
                  ),

                  // Right-Side Category Action Panel
                  Container(
                    width: 96,
                    margin: const EdgeInsets.only(right: 12, top: 4, bottom: 80),
                    child: _buildRightSideCategoryPanel(context, pct, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Student Welcome Banner
  Widget _buildTopWelcome(BuildContext context, dynamic user, double pct, bool isDark) {
    final isSafe = pct >= 75.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hello, ${user.name}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSafe
                            ? AppTheme.statusPresent.withValues(alpha: 0.12)
                            : AppTheme.statusAbsent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isSafe ? 'ELIGIBLE' : 'CRITICAL',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isSafe ? AppTheme.statusPresent : AppTheme.statusAbsent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Reg: ${user.rollNumber ?? "N/A"} • ${user.department} (Sem ${user.semester ?? 6})',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                  ),
                ),
              ],
            ),
          ),
          // AI Chatbot Quick Icon
          IconButton.filledTonal(
            icon: const Icon(Icons.auto_awesome, size: 18),
            tooltip: 'Chat with Campus AI',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
              foregroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AiChatbotSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Critical Attendance Alert
  Widget _buildCriticalAlert(BuildContext context, double pct, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.statusAbsent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statusAbsent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.statusAbsent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Attendance at $pct% is below 75% limit. Appeal condonation.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppTheme.statusAbsent,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => ApplyCondonationDialog(currentPercentage: pct),
              );
            },
            child: const Text('Appeal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // Horizontal Category Navigation Bar
  Widget _buildCategoryNavBar(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return InkWell(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                    : (isDark ? AppTheme.darkPanel : AppTheme.lightPanel),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                      : (isDark ? AppTheme.darkLine : AppTheme.lightLine),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 14,
                    color: isSelected
                        ? (isDark ? const Color(0xFF072722) : Colors.white)
                        : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? const Color(0xFF072722) : Colors.white)
                          : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Right-Side Category Action Panel
  Widget _buildRightSideCategoryPanel(BuildContext context, double pct, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Section Label
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'CATEGORIES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
          ),

          // 1. Attendance Overview Button
          _categoryTile(
            title: 'Attendance',
            icon: Icons.pie_chart_rounded,
            isSelected: _selectedCategoryIndex == 0,
            isDark: isDark,
            onTap: () => setState(() => _selectedCategoryIndex = 0),
          ),
          const SizedBox(height: 8),

          // 2. Applying Leave / OD Button
          _categoryTile(
            title: 'Apply\nLeave / OD',
            icon: Icons.event_note_rounded,
            isSelected: _selectedCategoryIndex == 3,
            isDark: isDark,
            isAction: true,
            onTap: () {
              setState(() => _selectedCategoryIndex = 3);
              showDialog(
                context: context,
                builder: (ctx) => const ApplyLeaveDialog(),
              );
            },
          ),
          const SizedBox(height: 8),

          // 3. Monthly Attendance Checks Button
          _categoryTile(
            title: 'Monthly\nChecks',
            icon: Icons.calendar_month_rounded,
            isSelected: _selectedCategoryIndex == 1,
            isDark: isDark,
            onTap: () => setState(() => _selectedCategoryIndex = 1),
          ),
          const SizedBox(height: 8),

          // 4. Subject Breakdown Button
          _categoryTile(
            title: 'Subject\nBreakdown',
            icon: Icons.menu_book_rounded,
            isSelected: _selectedCategoryIndex == 2,
            isDark: isDark,
            onTap: () => setState(() => _selectedCategoryIndex = 2),
          ),
          const SizedBox(height: 8),

          // 5. Campus AI Assistant Button
          _categoryTile(
            title: 'Campus AI\nAssistant',
            icon: Icons.auto_awesome_rounded,
            isSelected: false,
            isDark: isDark,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const AiChatbotSheet(),
              );
            },
          ),
          const SizedBox(height: 8),

          // 6. Condonation Button (if critical)
          if (pct < 75.0)
            _categoryTile(
              title: 'Condonation\nAppeal',
              icon: Icons.assignment_late_rounded,
              isSelected: false,
              isDark: isDark,
              highlightColor: AppTheme.statusAbsent,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ApplyCondonationDialog(currentPercentage: pct),
                );
              },
            ),
        ],
      ),
    );
  }

  // Single Right-Side Category Button Tile
  Widget _categoryTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    bool isAction = false,
    Color? highlightColor,
  }) {
    final activeColor = highlightColor ?? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : (isDark ? AppTheme.darkPanel : AppTheme.lightPanel),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppTheme.darkLine : AppTheme.lightLine),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : (isDark ? AppTheme.darkSoft : AppTheme.lightSoft),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? (isDark ? const Color(0xFF072722) : Colors.white)
                    : (highlightColor ?? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Selected Category View Renderer
  Widget _buildSelectedCategoryContent(
    BuildContext context,
    AttendanceProvider provider,
    double pct,
    int attended,
    int total,
    int lates,
    int latesAsAbs,
    int excused,
    List<dynamic> studentRecords,
    List<dynamic> studentLeaves,
    List<Map<String, dynamic>> subjectStats,
    bool isDark,
  ) {
    switch (_selectedCategoryIndex) {
      case 0:
        return _buildAttendanceOverview(
          context,
          provider,
          pct,
          attended,
          total,
          lates,
          latesAsAbs,
          excused,
          studentRecords,
          isDark,
        );
      case 1:
        return _buildMonthlyAttendanceView(context, studentRecords, isDark);
      case 2:
        return _buildSubjectBreakdownView(context, subjectStats, isDark);
      case 3:
        return _buildLeaveAndOdView(context, studentLeaves, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // View 0: Attendance Overview
  Widget _buildAttendanceOverview(
    BuildContext context,
    AttendanceProvider provider,
    double pct,
    int attended,
    int total,
    int lates,
    int latesAsAbs,
    int excused,
    List<dynamic> records,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Attendance Gauge Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              children: [
                AttendanceRadialGauge(
                  percentage: pct,
                  attended: attended,
                  total: total,
                  lates: lates,
                  threshold: provider.settings.attendanceLimit.toDouble(),
                  size: 160,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Key Attendance Counters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Attended', '$attended', AppTheme.statusPresent, isDark),
                    _metricCol('Lates', '$lates', AppTheme.statusLate, isDark),
                    _metricCol('Total', '$total', isDark ? AppTheme.darkFg : AppTheme.lightFg, isDark),
                    _metricCol('Excused', '$excused', AppTheme.darkAccent, isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // University Attendance Policy Summary
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.policy_outlined, size: 16, color: AppTheme.lightAccent),
                    const SizedBox(width: 6),
                    Text(
                      'COLLEGE RULES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _policyRuleRow('Exam Eligibility Limit', '${provider.settings.attendanceLimit}%', isDark),
                _policyRuleRow('Grace Period', '${provider.settings.lateWindowMinutes} mins', isDark),
                _policyRuleRow('Tardy Conversion', '${provider.settings.latesPerAbsence} lates = 1 abs', isDark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recent Taps Header
        Text(
          'RECENT TAP LOGS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
          ),
        ),
        const SizedBox(height: 6),
        ...records.take(4).map((r) {
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: Icon(
                r.status.isAttended ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: r.status.isAttended ? AppTheme.statusPresent : AppTheme.statusAbsent,
                size: 20,
              ),
              title: Text(
                DateFormat('dd MMM, hh:mm a').format(r.timestamp),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Room: ${r.room} • ${r.verificationMethod.name.toUpperCase()}',
                style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
              ),
              trailing: StatusBadge.fromAttendance(r.status),
            ),
          );
        }),
      ],
    );
  }

  // View 1: Monthly Attendance Checks
  Widget _buildMonthlyAttendanceView(BuildContext context, List<dynamic> records, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MONTHLY ATTENDANCE CHECKS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Interactive Calendar Heatmap
        AttendanceCalendarView(records: records.cast()),
        const SizedBox(height: 12),
        // Quick Tips
        Card(
          elevation: 0,
          color: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppTheme.lightAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap any day on the calendar above to inspect session entry times, verification RFID tag, and classroom details.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // View 2: Subject Breakdown
  Widget _buildSubjectBreakdownView(
    BuildContext context,
    List<Map<String, dynamic>> subjectStats,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUBJECT-WISE ATTENDANCE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
          ),
        ),
        const SizedBox(height: 8),
        ...subjectStats.map((item) {
          final sub = item['subject'];
          final subPct = item['percentage'] as double;
          final isSubSafe = subPct >= 75.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${sub.code}: ${sub.name}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${subPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isSubSafe ? AppTheme.statusPresent : AppTheme.statusAbsent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (subPct / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF23302B) : const Color(0xFFE2EBE7),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSubSafe ? AppTheme.statusPresent : AppTheme.statusAbsent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSubSafe ? 'Exam safe' : 'Shortage alert (< 75%)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSubSafe ? AppTheme.statusPresent : AppTheme.statusAbsent,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // View 3: Leave & OD
  Widget _buildLeaveAndOdView(BuildContext context, List<dynamic> leaves, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LEAVE & ON-DUTY (OD)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const ApplyLeaveDialog(),
                );
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Apply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (leaves.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available_rounded, size: 36, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                    const SizedBox(height: 8),
                    const Text('No leave applications yet', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Apply" or the right-side button to request leave or on-duty.',
                      style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...leaves.map((l) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                  '${l.type.displayName} (${DateFormat('dd MMM').format(l.startDate)} - ${DateFormat('dd MMM').format(l.endDate)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l.reason,
                  style: TextStyle(fontSize: 10.5, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                ),
                trailing: StatusBadge.fromRequestStatus(l.status),
              ),
            );
          }),
      ],
    );
  }

  Widget _metricCol(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
          ),
        ),
      ],
    );
  }

  Widget _policyRuleRow(String rule, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rule, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
          Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkFg : AppTheme.lightFg)),
        ],
      ),
    );
  }
}
