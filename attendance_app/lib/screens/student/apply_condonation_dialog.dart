import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class ApplyCondonationDialog extends StatefulWidget {
  final double currentPercentage;

  const ApplyCondonationDialog({super.key, required this.currentPercentage});

  @override
  State<ApplyCondonationDialog> createState() => _ApplyCondonationDialogState();
}

class _ApplyCondonationDialogState extends State<ApplyCondonationDialog> {
  String? _selectedSubjectId;
  String _selectedSubjectName = '';
  final _reasonController = TextEditingController();
  String _fileName = 'Apollo_Hospital_Discharge_Summary.pdf';

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    if (provider.subjects.isNotEmpty) {
      _selectedSubjectId = provider.subjects.first.id;
      _selectedSubjectName = provider.subjects.first.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.statusAbsent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.assignment_late_rounded, color: AppTheme.statusAbsent, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply for Condonation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppTheme.darkFg : AppTheme.lightFg,
                          ),
                        ),
                        Text(
                          'Exemption request to Head of Department (HOD)',
                          style: TextStyle(
                            fontSize: 11,
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
              const SizedBox(height: 16),

              // Attendance Warning Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.statusAbsent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.statusAbsent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.statusAbsent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your current attendance is ${widget.currentPercentage}%, below the mandatory 75% limit. Provide medical proof to avoid being debarred from exams.',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.statusAbsent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Subject Dropdown
              Text(
                'AFFECTED SUBJECT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: provider.subjects.map((s) {
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Text('${s.code} - ${s.name}', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSubjectId = val;
                    _selectedSubjectName = provider.subjects.firstWhere((s) => s.id == val).name;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Medical Reason
              TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Medical / Exceptional Reason',
                  hintText: 'e.g. Acute viral fever hospitalization for 2 weeks with doctor certificate.',
                ),
              ),
              const SizedBox(height: 12),

              // Proof Document Upload Simulation
              Text(
                'ATTACH MEDICAL / SUPPORTING PROOF (STORAGE)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkPanel : AppTheme.lightPanel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkLine : AppTheme.lightLine),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.statusAbsent, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Verified Doctor Signature • 1.4 MB',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _fileName = 'Govt_Hospital_Medical_Cert_${DateTime.now().day}.pdf';
                        });
                      },
                      child: const Text('Change', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_reasonController.text.trim().isEmpty || _selectedSubjectId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please state the medical reason.')),
                      );
                      return;
                    }
                    provider.submitCondonation(
                      subjectId: _selectedSubjectId!,
                      subjectName: _selectedSubjectName,
                      currentPercentage: widget.currentPercentage,
                      reason: _reasonController.text.trim(),
                      fileName: _fileName,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Condonation submitted! Transmitted to HOD console for decision.'),
                        backgroundColor: AppTheme.statusPresent,
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('SUBMIT CONDONATION TO HOD', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
