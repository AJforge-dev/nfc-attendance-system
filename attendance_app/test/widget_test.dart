import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_app/models/user.dart';
import 'package:attendance_app/models/leave_request.dart';
import 'package:attendance_app/models/device.dart';
import 'package:attendance_app/providers/attendance_provider.dart';

void main() {
  group('NFC Attendance Calculation & Policy Tests', () {
    late AttendanceProvider provider;

    setUp(() {
      provider = AttendanceProvider();
    });

    test('Initial student Priya has expected records and attendance percentage', () {
      final stats = provider.getStudentAttendanceStats('std_priya');
      final pct = stats['percentage'] as double;
      expect(pct, greaterThanOrEqualTo(80.0));
      expect(stats['present'], greaterThanOrEqualTo(2));
    });

    test('3 Lates = 1 Absence rule converts accurately', () {
      // Create test provider state
      final stats = provider.getStudentAttendanceStats('std_karthik');
      final lates = stats['late'] as int;
      final latesAsAbsence = stats['latesAsAbsence'] as int;
      expect(latesAsAbsence, equals(lates ~/ 3));
    });

    test('Simulating on-time scan (<= 10 mins) marks student PRESENT', () {
      final result = provider.simulateNfcScan(
        tagUid: '4A7B12C9', // Priya
        deviceId: 'ESP32_ROOM_302',
        minutesOffsetFromStart: 5, // On-time
      );

      expect(result['success'], isTrue);
      expect(result['code'], equals(200));
      expect(result['status'], equals('present'));
    });

    test('Simulating late scan (> 10 mins) marks student LATE', () {
      final result = provider.simulateNfcScan(
        tagUid: '7C9A34D1', // Ananya
        deviceId: 'ESP32_ROOM_302',
        minutesOffsetFromStart: 18, // Late!
      );

      expect(result['success'], isTrue);
      expect(result['code'], equals(200));
      expect(result['status'], equals('late'));
    });

    test('Simulating duplicate scan returns 409 conflict', () {
      // First scan
      provider.simulateNfcScan(
        tagUid: '4A7B12C9',
        deviceId: 'ESP32_ROOM_302',
        minutesOffsetFromStart: 4,
      );

      // Second scan in same active session
      final duplicateResult = provider.simulateNfcScan(
        tagUid: '4A7B12C9',
        deviceId: 'ESP32_ROOM_302',
        minutesOffsetFromStart: 6,
      );

      expect(duplicateResult['success'], isFalse);
      expect(duplicateResult['code'], equals(409));
      expect(duplicateResult['status'], equals('duplicate'));
    });

    test('Unregistered RFID card logs an anomaly and returns 404', () {
      final initialAnomalyCount = provider.anomalies.length;
      final result = provider.simulateNfcScan(
        tagUid: 'UNKNOWN_TAG_99',
        deviceId: 'ESP32_ROOM_302',
        minutesOffsetFromStart: 4,
      );

      expect(result['success'], isFalse);
      expect(result['code'], equals(404));
      expect(provider.anomalies.length, equals(initialAnomalyCount + 1));
      expect(provider.anomalies.first.type, equals('unregistered_tag'));
    });

    test('Advisor approving Leave marks sessions Excused and excludes from total', () {
      // Find pending leave request for Karthik
      final pendingLeaves = provider.leaveRequests.where((l) => l.status == RequestStatus.pending).toList();
      expect(pendingLeaves.isNotEmpty, isTrue);

      final targetId = pendingLeaves.first.id;
      provider.decideLeaveRequest(targetId, true, remark: 'Approved for symposium');

      final updated = provider.leaveRequests.firstWhere((l) => l.id == targetId);
      expect(updated.status, equals(RequestStatus.approved));
    });

    test('Student risk engine categorizes high risk students below 75%', () {
      final riskScores = provider.getRiskScores();
      final karthikRisk = riskScores.firstWhere((r) => r.studentId == 'std_karthik');
      expect(karthikRisk.score, equals(RiskLevel.high));
      expect(karthikRisk.reasons.any((r) => r.contains('75%')), isTrue);
    });

    test('Role switching dynamically updates active user and role permissions', () {
      provider.switchRole(UserRole.hod);
      expect(provider.currentUser.role, equals(UserRole.hod));

      provider.switchRole(UserRole.admin);
      expect(provider.currentUser.role, equals(UserRole.admin));

      provider.switchRole(UserRole.student);
      expect(provider.currentUser.role, equals(UserRole.student));
    });

    test('Student login with Register No and Password succeeds for valid student', () {
      final res = provider.loginWithRegisterNo('21CS042', 'password123');
      expect(res['success'], isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.currentUser.rollNumber, equals('21CS042'));

      provider.logout();
      expect(provider.isLoggedIn, isFalse);

      final failed = provider.loginWithRegisterNo('21CS042', 'wrongpass');
      expect(failed['success'], isFalse);
      expect(provider.isLoggedIn, isFalse);
    });

    test('Student registration creates student profile and allows immediate login', () {
      final regNo = '21IT999';
      final pass = 'newpass@2026';
      final dob = DateTime(2003, 5, 20);

      final result = provider.registerStudent(
        name: 'Vikas Sharma',
        registerNo: regNo,
        dob: dob,
        password: pass,
        department: 'Information Technology',
        semester: 6,
      );

      expect(result['success'], isTrue);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.currentUser.name, equals('Vikas Sharma'));
      expect(provider.currentUser.rollNumber, equals(regNo));
      expect(provider.currentUser.dob, equals(dob));

      provider.logout();
      final loginRes = provider.loginWithRegisterNo(regNo, pass);
      expect(loginRes['success'], isTrue);
      expect(provider.isLoggedIn, isTrue);
    });

    test('Email OTP password reset works end-to-end', () {
      final otpResult = provider.sendPasswordResetOtp('21CS088'); // Karthik
      expect(otpResult['success'], isTrue);
      final otp = otpResult['otp'] as String;
      expect(otp.length, equals(6));

      // Reset password with received OTP
      final resetRes = provider.verifyOtpAndResetPassword(otp, 'newkarthik@2026');
      expect(resetRes['success'], isTrue);

      // Verify login with new password
      final canLogin = provider.loginWithRegisterNo('21CS088', 'newkarthik@2026');
      expect(canLogin['success'], isTrue);
    });

    test('Emergency Admin Access Code locks and unlocks emergency tap scan', () {
      // Default code is 9821
      expect(provider.emergencyAdminAccessCode, equals('9821'));
      expect(provider.verifyEmergencyCode('9821'), isTrue);
      expect(provider.verifyEmergencyCode('0000'), isFalse);

      // Admin generates new code
      final newCode = provider.generateNewAdminAccessCode();
      expect(newCode.length, equals(4));
      expect(provider.verifyEmergencyCode(newCode), isTrue);
      expect(provider.verifyEmergencyCode('9821'), isFalse);

      // Admin sets custom code
      provider.setAdminAccessCode('5566');
      expect(provider.verifyEmergencyCode('5566'), isTrue);
    });
  });
}

