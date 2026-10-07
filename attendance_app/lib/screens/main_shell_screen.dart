import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/attendance_provider.dart';
import '../widgets/role_switcher_banner.dart';
import '../widgets/emergency_tap_dialog.dart';
import 'auth/login_screen.dart';
import 'student/student_home_screen.dart';
import 'faculty/faculty_home_screen.dart';
import 'advisor/advisor_home_screen.dart';
import 'hod/hod_home_screen.dart';
import 'admin/admin_home_screen.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }

    final role = provider.currentUser.role;

    Widget body;
    switch (role) {
      case UserRole.student:
        body = const StudentHomeScreen();
        break;
      case UserRole.faculty:
        body = const FacultyHomeScreen();
        break;
      case UserRole.advisor:
        body = const AdvisorHomeScreen();
        break;
      case UserRole.hod:
        body = const HodHomeScreen();
        break;
      case UserRole.admin:
        body = const AdminHomeScreen();
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const RoleSwitcherBanner(),
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: const EmergencyTapWidget(),
    );
  }
}

