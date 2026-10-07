import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';

class NfcScanSimulatorDialog extends StatefulWidget {
  const NfcScanSimulatorDialog({super.key});

  @override
  State<NfcScanSimulatorDialog> createState() => _NfcScanSimulatorDialogState();
}

class _NfcScanSimulatorDialogState extends State<NfcScanSimulatorDialog> {
  String? _selectedTagUid;
  String? _selectedDeviceId;
  int _minutesOffset = 4; // Default on-time: 4 minutes
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    _selectedTagUid = '4A7B12C9'; // Priya
    if (provider.devices.isNotEmpty) {
      _selectedDeviceId = provider.devices.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentOptions = [
      {'name': 'Priya Sharma (21CS042)', 'tag': '4A7B12C9'},
      {'name': 'Karthik Rajan (21CS088)', 'tag': '5F8E21B0'},
      {'name': 'Ananya Krishnan (21CS014)', 'tag': '7C9A34D1'},
      {'name': 'Unknown / Stolen Card (Anomaly Test)', 'tag': 'E9A1320F'},
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSoft : AppTheme.lightSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.nfc_rounded,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESP32 NFC Tap Simulator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                          ),
                        ),
                        Text(
                          'Simulates RFID tap & Cloud Function decision',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Student Card Selection
              Text(
                '1. SELECT STUDENT NFC CARD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedTagUid,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: studentOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['tag'],
                    child: Text(
                      '${opt['name']} [${opt['tag']}]',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTagUid = val),
              ),
              const SizedBox(height: 14),

              // Device / Classroom Selection
              Text(
                '2. SELECT ESP32 READER (CLASSROOM)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedDeviceId,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: provider.devices.map((d) {
                  return DropdownMenuItem<String>(
                    value: d.id,
                    child: Text(
                      '${d.room} (${d.id}) - ${d.status.toUpperCase()}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDeviceId = val),
              ),
              const SizedBox(height: 14),

              // Tap Timing (On-time vs Late)
              Text(
                '3. TAP TIMING (SESSION START OFFSET)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('On-Time (+4 min)'),
                      selected: _minutesOffset <= 10,
                      selectedColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _minutesOffset <= 10
                            ? (isDark ? const Color(0xFF072722) : Colors.white)
                            : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                      ),
                      onSelected: (_) => setState(() => _minutesOffset = 4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Late (+16 min)'),
                      selected: _minutesOffset > 10,
                      selectedColor: AppTheme.statusLate,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _minutesOffset > 10 ? Colors.black87 : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                      ),
                      onSelected: (_) => setState(() => _minutesOffset = 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Result Banner if triggered
              if (_lastResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getResultColor(_lastResult!).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getResultColor(_lastResult!).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastResult!['success'] == true ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        color: _getResultColor(_lastResult!),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HTTP ${_lastResult!['code']}: ${_lastResult!['status'].toString().toUpperCase()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _getResultColor(_lastResult!),
                              ),
                            ),
                            Text(
                              _lastResult!['message'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Tap Card Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_selectedTagUid == null || _selectedDeviceId == null) return;
                    final res = provider.simulateNfcScan(
                      tagUid: _selectedTagUid!,
                      deviceId: _selectedDeviceId!,
                      minutesOffsetFromStart: _minutesOffset,
                    );
                    setState(() {
                      _lastResult = res;
                    });
                  },
                  icon: const Icon(Icons.tap_and_play_rounded),
                  label: const Text('TAP NFC CARD NOW', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResultColor(Map<String, dynamic> result) {
    if (result['code'] == 200) {
      return result['status'] == 'present' ? AppTheme.statusPresent : AppTheme.statusLate;
    }
    if (result['code'] == 409) return AppTheme.statusLate;
    return AppTheme.statusAbsent;
  }
}
