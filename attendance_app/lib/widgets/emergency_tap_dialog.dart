import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';
import 'nfc_scan_simulator_dialog.dart';

class EmergencyTapWidget extends StatelessWidget {
  const EmergencyTapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? AppTheme.darkPanel : AppTheme.lightPanel;
    final accent = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => const EmergencyAuthDialog(),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: panelBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(
                    Icons.nfc_rounded,
                    color: accent,
                    size: 28,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.statusLate,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock, size: 8, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Tap to Scan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'EMERGENCY',
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: AppTheme.statusLate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyAuthDialog extends StatefulWidget {
  const EmergencyAuthDialog({super.key});

  @override
  State<EmergencyAuthDialog> createState() => _EmergencyAuthDialogState();
}

class _EmergencyAuthDialogState extends State<EmergencyAuthDialog> {
  final _codeController = TextEditingController();
  String? _errorMessage;

  void _verifyAndProceed() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the Admin Access Code');
      return;
    }

    final provider = context.read<AttendanceProvider>();
    if (provider.verifyEmergencyCode(code)) {
      Navigator.pop(context); // Close auth prompt
      // Open simulator
      showDialog(
        context: context,
        builder: (ctx) => const NfcScanSimulatorDialog(),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid Admin Access Code. Check with Administrator.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.statusLate.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.statusLate, size: 24),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Manual Tap',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Admin Authorization Required',
                  style: TextStyle(fontSize: 11, color: AppTheme.lightMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual card scans are restricted for emergency situations (hardware offline or reader failure). Enter the Admin Access Code generated from the Admin Console.',
            style: TextStyle(fontSize: 12, color: AppTheme.lightMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 4),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••',
              labelText: 'Admin Access Code',
              prefixIcon: Icon(Icons.key_rounded, color: AppTheme.lightAccent),
            ),
            onSubmitted: (_) => _verifyAndProceed(),
          ),
          const SizedBox(height: 6),
          // Demo hint showing current active code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.lightSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightLine),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.lightAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Active Admin Code: ${provider.emergencyAdminAccessCode}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.lightAccent),
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.statusAbsent),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _verifyAndProceed,
          icon: const Icon(Icons.lock_open_rounded, size: 16),
          label: const Text('AUTHORIZE & SCAN'),
        ),
      ],
    );
  }
}
