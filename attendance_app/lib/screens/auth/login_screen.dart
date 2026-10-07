import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/attendance_provider.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _registerNoController = TextEditingController(text: '21CS042'); // Priya Sharma default
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleLogin() {
    final regNo = _registerNoController.text.trim();
    final pass = _passwordController.text.trim();

    if (regNo.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter both Register Number and Password');
      return;
    }

    final provider = context.read<AttendanceProvider>();
    final res = provider.loginWithRegisterNo(regNo, pass);

    if (res['success'] == true) {
      setState(() => _errorMessage = null);
    } else {
      setState(() => _errorMessage = res['message'] ?? 'Login failed');
    }
  }

  void _showForgotPasswordDialog() {
    final resetInputController = TextEditingController(text: _registerNoController.text);
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    String? generatedOtp;
    String? userEmail;
    bool otpSent = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.lightAccent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Reset Password (OTP)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!otpSent) ...[
                    const Text(
                      'Enter your Register Number or registered email address to receive a 6-digit verification code.',
                      style: TextStyle(fontSize: 12, color: AppTheme.lightMuted),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: resetInputController,
                      decoration: const InputDecoration(
                        labelText: 'Register Number or Email',
                        hintText: 'e.g. 21CS042',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.lightSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.lightLine),
                      ),
                      child: Text(
                        'Demo OTP sent to $userEmail\nCode: $generatedOtp',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.lightAccent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter 6-Digit OTP',
                        prefixIcon: Icon(Icons.lock_clock_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                      ),
                    ),
                  ],
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(dialogError!, style: const TextStyle(fontSize: 11, color: AppTheme.statusAbsent, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                if (!otpSent)
                  ElevatedButton(
                    onPressed: () {
                      final input = resetInputController.text.trim();
                      if (input.isEmpty) {
                        setDialogState(() => dialogError = 'Enter Register Number or Email');
                        return;
                      }
                      final provider = context.read<AttendanceProvider>();
                      final res = provider.sendPasswordResetOtp(input);
                      if (res['success'] == true) {
                        setDialogState(() {
                          otpSent = true;
                          generatedOtp = res['otp'];
                          userEmail = res['email'];
                          dialogError = null;
                        });
                      } else {
                        setDialogState(() => dialogError = res['message']);
                      }
                    },
                    child: const Text('Send OTP'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      final otp = otpController.text.trim();
                      final newPass = newPasswordController.text.trim();
                      if (otp.isEmpty || newPass.isEmpty) {
                        setDialogState(() => dialogError = 'Enter both OTP and new password');
                        return;
                      }
                      final provider = context.read<AttendanceProvider>();
                      final res = provider.verifyOtpAndResetPassword(otp, newPass);
                      if (res['success'] == true) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password updated successfully! You can now log in.'),
                            backgroundColor: AppTheme.statusPresent,
                          ),
                        );
                      } else {
                        setDialogState(() => dialogError = res['message']);
                      }
                    },
                    child: const Text('Update Password'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // College Logo / Header Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.lightSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.lightAccent.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppTheme.lightAccent,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Campus NFC Attendance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.lightFg,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Student & Staff Portal Sign In',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.lightMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login Form Card
                  Card(
                    color: AppTheme.lightPanel,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppTheme.lightMuted,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Register Number Input
                          TextField(
                            controller: _registerNoController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Register Number',
                              hintText: 'e.g. 21CS042',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.lightAccent),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password Input
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.lightAccent),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(),
                          ),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot Password? (OTP)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.lightAccent,
                                ),
                              ),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 12),
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

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              child: const Text(
                                'LOGIN TO PORTAL',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('New student?', style: TextStyle(fontSize: 13, color: AppTheme.lightMuted)),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: const Text(
                                  'Register Here',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.lightAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Demo Selector for Presentation
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.lightLine),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ QUICK DEMO LOGINS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppTheme.lightMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _demoChip('Priya (Student 88%)', '21CS042', () {
                              _registerNoController.text = '21CS042';
                              _passwordController.text = 'password123';
                              _handleLogin();
                            }),
                            _demoChip('Karthik (Student 71%)', '21CS088', () {
                              _registerNoController.text = '21CS088';
                              _passwordController.text = 'password123';
                              _handleLogin();
                            }),
                            _demoChip('Faculty Portal', 'fac_sundar', () {
                              provider.switchRole(UserRole.faculty);
                            }),
                            _demoChip('Advisor Portal', 'adv_meenakshi', () {
                              provider.switchRole(UserRole.advisor);
                            }),
                            _demoChip('HOD Console', 'hod_vijay', () {
                              provider.switchRole(UserRole.hod);
                            }),
                            _demoChip('Admin Console', 'adm_admin', () {
                              provider.switchRole(UserRole.admin);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String label, String reg, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.lightSoft,
      labelStyle: const TextStyle(color: AppTheme.lightAccent),
      side: const BorderSide(color: AppTheme.lightLine),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onTap,
    );
  }
}
