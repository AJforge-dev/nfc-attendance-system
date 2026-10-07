import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class ApplyLeaveDialog extends StatefulWidget {
  const ApplyLeaveDialog({super.key});

  @override
  State<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  LeaveType _type = LeaveType.leave;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apply Leave / On-Duty (OD)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Type Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Personal / Medical Leave'),
                      selected: _type == LeaveType.leave,
                      selectedColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _type == LeaveType.leave
                            ? (isDark ? const Color(0xFF072722) : Colors.white)
                            : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                      ),
                      onSelected: (_) => setState(() => _type = LeaveType.leave),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('On-Duty (OD)'),
                      selected: _type == LeaveType.od,
                      selectedColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _type == LeaveType.od
                            ? (isDark ? const Color(0xFF072722) : Colors.white)
                            : (isDark ? AppTheme.darkFg : AppTheme.lightFg),
                      ),
                      onSelected: (_) => setState(() => _type = LeaveType.od),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Date Selectors
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        'From: ${DateFormat('dd MMM').format(_startDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        'To: ${DateFormat('dd MMM').format(_endDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Reason Input
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for absence',
                  hintText: 'e.g. Attending Anna University tech symposium...',
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_reasonController.text.trim().isEmpty) return;
                    context.read<AttendanceProvider>().submitLeaveRequest(
                          type: _type,
                          startDate: _startDate,
                          endDate: _endDate,
                          reason: _reasonController.text.trim(),
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Request submitted! Sent to Class Advisor for approval.'),
                        backgroundColor: AppTheme.statusPresent,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('SUBMIT TO ADVISOR', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
