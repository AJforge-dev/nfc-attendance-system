import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _registerNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _dob;
  String _department = 'Computer Science & Engineering';
  final int _semester = 6;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleRegister() {
    final name = _nameController.text.trim();
    final regNo = _registerNoController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (name.isEmpty || regNo.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required fields');
      return;
    }

    if (_dob == null) {
      setState(() => _errorMessage = 'Please select your Date of Birth (DOB)');
      return;
    }

    if (pass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    final provider = context.read<AttendanceProvider>();
    final res = provider.registerStudent(
      name: name,
      registerNo: regNo,
      dob: _dob!,
      password: pass,
      department: _department,
      semester: _semester,
    );

    if (res['success'] == true) {
      Navigator.pop(context); // Return to login / portal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, $name! Registered successfully.'),
          backgroundColor: AppTheme.statusPresent,
        ),
      );
    } else {
      setState(() => _errorMessage = res['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Student Registration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                color: AppTheme.lightPanel,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.lightSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.lightAccent, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Student Account',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.lightFg),
                              ),
                              Text(
                                'Enroll into the Campus NFC system',
                                style: TextStyle(fontSize: 12, color: AppTheme.lightMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Full Name
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'e.g. Rahul Verma',
                          prefixIcon: Icon(Icons.person_outline, color: AppTheme.lightAccent),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Register Number
                      TextField(
                        controller: _registerNoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Register Number / Roll No *',
                          hintText: 'e.g. 21CS105',
                          prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.lightAccent),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Date of Birth (DOB) Picker
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2003, 1, 1),
                            firstDate: DateTime(1995),
                            lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
                          );
                          if (picked != null) {
                            setState(() => _dob = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth (DOB) *',
                            prefixIcon: Icon(Icons.calendar_month_outlined, color: AppTheme.lightAccent),
                          ),
                          child: Text(
                            _dob != null ? DateFormat('dd MMMM yyyy').format(_dob!) : 'Select Date of Birth',
                            style: TextStyle(
                              color: _dob != null ? AppTheme.lightFg : AppTheme.lightMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Department
                      DropdownButtonFormField<String>(
                        initialValue: _department,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.domain_outlined, color: AppTheme.lightAccent),
                        ),
                        items: [
                          'Computer Science & Engineering',
                          'Information Technology',
                          'Electronics & Communication',
                          'Mechanical Engineering',
                        ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _department = val ?? _department),
                      ),
                      const SizedBox(height: 14),

                      // Password Setting
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password Setting *',
                          hintText: 'Min 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.lightAccent),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password *',
                          prefixIcon: Icon(Icons.lock_reset_rounded, color: AppTheme.lightAccent),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.statusAbsent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.statusAbsent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.statusAbsent, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _handleRegister,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text(
                            'COMPLETE REGISTRATION',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
