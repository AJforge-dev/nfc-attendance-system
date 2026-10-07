import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                        'Campus Admin Console',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                        ),
                      ),
                      Text(
                        '${user.name} • IT Operations & Devices',
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
              tabs: const [
                Tab(text: 'ESP32 Readers'),
                Tab(text: 'NFC Enrollment'),
                Tab(text: 'College Policy'),
              ],
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDevicesTab(context, provider),
          _buildEnrollmentTab(context, provider),
          _buildSettingsTab(context, provider),
        ],
      ),
    );
  }

  Widget _buildDevicesTab(BuildContext context, AttendanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.devices.length,
      itemBuilder: (context, index) {
        final d = provider.devices[index];
        final isOnline = d.isOnline;

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
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isOnline ? AppTheme.statusPresent : AppTheme.statusAbsent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${d.room} (${d.id})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOnline ? AppTheme.statusPresent : AppTheme.statusAbsent).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isOnline ? AppTheme.statusPresent : AppTheme.statusAbsent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Auth Bearer Token: ${d.token}',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  'WiFi Signal: ${d.rssi} dBm • Offline Queue: ${d.queueSize} items • Last Heartbeat: ${d.lastHeartbeat != null ? DateFormat("hh:mm:ss a").format(d.lastHeartbeat!) : "Never"}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnrollmentTab(BuildContext context, AttendanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final u = provider.users[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
              child: Text(
                u.name[0],
                style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
              ),
            ),
            title: Text('${u.name} (${u.role.displayName})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${u.department} • Tag UID: ${u.tagUid ?? "None"}',
              style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                u.tagUid ?? 'NO TAG',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context, AttendanceProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = provider.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Access Code Card (for Tap to Scan)
          Card(
            color: isDark ? const Color(0xFF1B2620) : const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppTheme.darkAccent.withValues(alpha: 0.4) : AppTheme.lightAccent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.statusLate.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.security_rounded, color: AppTheme.statusLate, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Tap Access Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                                ),
                              ),
                              Text(
                                'Required for student emergency "Tap to Scan"',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.statusPresent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.statusPresent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT PASSCODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSoft : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? AppTheme.darkLine : AppTheme.lightLine,
                              ),
                            ),
                            child: Text(
                              provider.emergencyAdminAccessCode,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                fontFamily: 'monospace',
                                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              _showCustomCodeDialog(context, provider);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Set Code', style: TextStyle(fontSize: 12)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final newCode = provider.generateNewAdminAccessCode();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Generated new Emergency Admin Code: $newCode'),
                                  backgroundColor: AppTheme.statusPresent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Generate New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Share this 4-digit code only during hardware reader outages or emergency roll-call situations.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // College Attendance Thresholds Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'College Attendance Thresholds',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkFg : AppTheme.lightFg),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stored per college in orgs/{orgId}/settings',
                    style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
                  ),
                  const Divider(height: 24),

                  // Late Window
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Late Window Grace Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('Taps after this count as LATE', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
                        ],
                      ),
                      Text(
                        '${settings.lateWindowMinutes} minutes',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Minimum Attendance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mandatory Exam Attendance Limit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('Below requires Condonation appeal', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
                        ],
                      ),
                      Text(
                        '${settings.attendanceLimit}%',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.statusLate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3 Lates Rule
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tardy to Absence Conversion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('Every N late arrivals count as 1 absence', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted)),
                        ],
                      ),
                      Text(
                        '${settings.latesPerAbsence} lates = 1 abs',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.statusAbsent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showCustomCodeDialog(BuildContext context, AttendanceProvider provider) {
    final controller = TextEditingController(text: provider.emergencyAdminAccessCode);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Emergency Access Code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a 4-digit numeric access code for emergency tap simulation:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Access Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                provider.setAdminAccessCode(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Emergency Code updated to: $val'),
                    backgroundColor: AppTheme.statusPresent,
                  ),
                );
              }
            },
            child: const Text('Save Code'),
          ),
        ],
      ),
    );
  }
}
