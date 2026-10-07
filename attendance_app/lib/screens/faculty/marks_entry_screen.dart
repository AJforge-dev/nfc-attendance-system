import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class MarksEntryDialog extends StatefulWidget {
  const MarksEntryDialog({super.key});

  @override
  State<MarksEntryDialog> createState() => _MarksEntryDialogState();
}

class _MarksEntryDialogState extends State<MarksEntryDialog> {
  String? _selectedStudentId;
  String? _selectedSubjectId;
  String _examType = 'Internal 1';
  final _marksController = TextEditingController(text: '42');
  final _maxMarksController = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    final students = provider.users.where((u) => u.role == UserRole.student).toList();
    if (students.isNotEmpty) _selectedStudentId = students.first.id;
    if (provider.subjects.isNotEmpty) _selectedSubjectId = provider.subjects.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final students = provider.users.where((u) => u.role == UserRole.student).toList();

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
                    'Enter Assessment Marks',
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

              // Student Dropdown
              Text(
                'STUDENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedStudentId,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: students.map((s) {
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Text('${s.name} (${s.rollNumber ?? "N/A"})', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedStudentId = val),
              ),
              const SizedBox(height: 12),

              // Subject Dropdown
              Text(
                'SUBJECT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: provider.subjects.map((s) {
                  return DropdownMenuItem<String>(
                    value: s.id,
                    child: Text('${s.code}: ${s.name}', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
              ),
              const SizedBox(height: 12),

              // Exam Type
              Text(
                'ASSESSMENT TYPE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _examType,
                isExpanded: true,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: ['Internal 1', 'Internal 2', 'Model Exam'].map((e) {
                  return DropdownMenuItem<String>(value: e, child: Text(e, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) => setState(() => _examType = val ?? 'Internal 1'),
              ),
              const SizedBox(height: 12),

              // Marks Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _marksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Marks Obtained',
                        hintText: 'e.g. 45',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _maxMarksController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Marks',
                        hintText: 'e.g. 50',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final marks = double.tryParse(_marksController.text.trim()) ?? 0.0;
                    final maxMarks = double.tryParse(_maxMarksController.text.trim()) ?? 50.0;
                    if (_selectedStudentId == null || _selectedSubjectId == null) return;

                    final subName = provider.subjects.firstWhere((s) => s.id == _selectedSubjectId).name;

                    provider.addOrUpdateMark(
                      studentId: _selectedStudentId!,
                      subjectId: _selectedSubjectId!,
                      subjectName: subName,
                      examType: _examType,
                      marksObtained: marks,
                      maxMarks: maxMarks,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marks saved for $_examType ($marks / $maxMarks). Risk engine updated!'),
                        backgroundColor: AppTheme.statusPresent,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('SAVE MARKS', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
