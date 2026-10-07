import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/device.dart';
import '../../models/leave_request.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class AdvisorHomeScreen extends StatefulWidget {
  const AdvisorHomeScreen({super.key});

  @override
  State<AdvisorHomeScreen> createState() => _AdvisorHomeScreenState();
}

class _AdvisorHomeScreenState extends State<AdvisorHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final user = provider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pendingCount = provider.leaveRequests.where((l) => l.status == RequestStatus.pending).length;
    final riskList = provider.getRiskScores();
    final highRiskCount = riskList.where((r) => r.score == RiskLevel.high).length;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Advisor Portal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                        ),
                      ),
                      Text(
                        '${user.name} • ${user.designation ?? user.department}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (highRiskCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.statusAbsent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$highRiskCount High Risk',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.statusAbsent),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              indicatorColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Leave & OD Requests'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: AppTheme.statusLate,
                          child: Text('$pendingCount', style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Student Risk Model'),
              ],
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaveApprovalsTab(context, provider),
          _buildRiskModelTab(context, riskList),
        ],
      ),
    );
  }

  Widget _buildLeaveApprovalsTab(BuildContext context, AttendanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requests = provider.leaveRequests;

    if (requests.isEmpty) {
      return Center(
        child: Text('No leave or OD applications submitted.', style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isPending = req.status == RequestStatus.pending;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${req.studentName} (${req.rollNumber})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                            ),
                          ),
                          Text(
                            req.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.fromRequestStatus(req.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Duration: ${DateFormat('dd MMM yyyy').format(req.startDate)} to ${DateFormat('dd MMM yyyy').format(req.endDate)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkFg : AppTheme.lightFg),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reason: ${req.reason}',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                ),
                if (req.remark != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Remark: ${req.remark}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],

                // Action buttons if pending
                if (isPending) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          provider.decideLeaveRequest(req.id, false, remark: 'Rejected by Advisor: Incomplete documentation');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Leave request rejected.')),
                          );
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.statusAbsent),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          provider.decideLeaveRequest(req.id, true, remark: 'Approved by Class Advisor. Sessions marked Excused.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Approved! Affected sessions marked Excused and percentage recalculated.'),
                              backgroundColor: AppTheme.statusPresent,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve (Excused)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskModelTab(BuildContext context, List<RiskScoreModel> riskList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: riskList.length,
      itemBuilder: (context, index) {
        final risk = riskList[index];
        Color riskColor;
        switch (risk.score) {
          case RiskLevel.high:
            riskColor = AppTheme.statusAbsent;
            break;
          case RiskLevel.medium:
            riskColor = AppTheme.statusLate;
            break;
          case RiskLevel.low:
            riskColor = AppTheme.statusPresent;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${risk.studentName} (${risk.rollNumber})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                            ),
                          ),
                          Text(
                            'Attendance: ${risk.attendanceRate}% • Tardy Lates: ${risk.lateCount} • Marks Avg: ${risk.marksAverage}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: riskColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        risk.score.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: riskColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'PREDICTIVE RISK REASONS:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                ...risk.reasons.map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right_rounded, size: 18, color: riskColor),
                          Expanded(
                            child: Text(
                              r,
                              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkFg : AppTheme.lightFg),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
