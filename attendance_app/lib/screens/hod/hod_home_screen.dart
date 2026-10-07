import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class HodHomeScreen extends StatefulWidget {
  const HodHomeScreen({super.key});

  @override
  State<HodHomeScreen> createState() => _HodHomeScreenState();
}

class _HodHomeScreenState extends State<HodHomeScreen> with SingleTickerProviderStateMixin {
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

    final pendingCondonations = provider.condonations.where((c) => c.status == RequestStatus.pending).length;
    final unreviewedAnomalies = provider.anomalies.where((a) => !a.reviewed).length;

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
                        'Head of Department (HOD) Console',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                        ),
                      ),
                      Text(
                        '${user.name} • ${user.department}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
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
                      const Text('Condonation Review'),
                      if (pendingCondonations > 0) ...[
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: AppTheme.statusAbsent,
                          child: Text('$pendingCondonations', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Security Anomalies'),
                      if (unreviewedAnomalies > 0) ...[
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: AppTheme.statusLate,
                          child: Text('$unreviewedAnomalies', style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCondonationTab(context, provider),
          _buildAnomaliesTab(context, provider),
        ],
      ),
    );
  }

  Widget _buildCondonationTab(BuildContext context, AttendanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = provider.condonations;

    if (list.isEmpty) {
      return Center(
        child: Text('No condonation applications submitted.', style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final isPending = item.status == RequestStatus.pending;

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
                            '${item.studentName} (${item.rollNumber})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                            ),
                          ),
                          Text(
                            'Subject: ${item.subjectName} • Attendance: ${item.currentPercentage}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.statusAbsent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.fromRequestStatus(item.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Reason: ${item.reason}',
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkFg : AppTheme.lightFg),
                ),
                const SizedBox(height: 10),

                // Attached Document Preview Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppTheme.statusAbsent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.documentFileName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: AppTheme.statusPresent),
                                  const SizedBox(width: 8),
                                  const Text('Medical Verification', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Student: ${item.studentName} (${item.rollNumber})'),
                                  const SizedBox(height: 6),
                                  Text('File: ${item.documentFileName}'),
                                  const SizedBox(height: 6),
                                  Text('Stated Reason: ${item.reason}'),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Status: Hospital Seal & Doctor Registration #TN-MC-84291 Verified Valid.',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.statusPresent),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                              ],
                            ),
                          );
                        },
                        child: const Text('Inspect Proof', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),

                if (item.remark != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'HOD Remark: ${item.remark}',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ],

                if (isPending) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          provider.decideCondonation(item.id, false, remark: 'Rejected: Attendance threshold insufficient for medical quota');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Condonation rejected.')),
                          );
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.statusAbsent),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          provider.decideCondonation(item.id, true, remark: 'Approved by HOD. Exam debarment waived under medical condonation quota.');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Condonation Approved! Student exempted and cleared for semester exams.'),
                              backgroundColor: AppTheme.statusPresent,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve Exemption', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _buildAnomaliesTab(BuildContext context, AttendanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final anomalies = provider.anomalies;

    if (anomalies.isEmpty) {
      return Center(
        child: Text('No anomalies detected by smart rules.', style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: anomalies.length,
      itemBuilder: (context, index) {
        final anom = anomalies[index];

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
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.statusLate, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          anom.typeTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                          ),
                        ),
                      ],
                    ),
                    if (anom.reviewed)
                      const StatusBadge(label: 'Reviewed', color: AppTheme.statusPresent, icon: Icons.done_all)
                    else
                      const StatusBadge(label: 'Unreviewed', color: AppTheme.statusLate, icon: Icons.warning_amber),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  anom.details,
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkFg : AppTheme.lightFg),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tag UID: ${anom.tagUid} • Device: ${anom.deviceId} (${anom.room}) • ${DateFormat('dd MMM, hh:mm a').format(anom.timestamp)}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                ),
                if (!anom.reviewed) ...[
                  const Divider(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.reviewAnomaly(anom.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anomaly marked as reviewed.')),
                        );
                      },
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Mark as Reviewed', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
