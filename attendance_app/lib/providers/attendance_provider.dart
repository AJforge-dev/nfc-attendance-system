import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';
import '../models/session.dart';
import '../models/leave_request.dart';
import '../models/condonation.dart';
import '../models/mark.dart';
import '../models/device.dart';
import '../services/mock_database.dart';

class AttendanceProvider extends ChangeNotifier {
  late List<UserModel> _users;
  late List<SubjectModel> _subjects;
  late List<DeviceModel> _devices;
  late List<SessionModel> _sessions;
  late List<AttendanceRecord> _records;
  late List<LeaveRequestModel> _leaveRequests;
  late List<CondonationModel> _condonations;
  late List<MarkModel> _marks;
  late List<AnomalyModel> _anomalies;
  OrgSettingsModel _settings = OrgSettingsModel();

  late UserModel _currentUser;
  SessionModel? _activeSession;
  bool _isLoggedIn = true;
  String _emergencyAdminAccessCode = '9821';
  String? _pendingResetOtp;
  String? _pendingResetUserId;

  AttendanceProvider() {
    _initData();
  }

  void _initData() {
    _users = List.from(MockDatabase.initialUsers);
    _subjects = List.from(MockDatabase.initialSubjects);
    _devices = List.from(MockDatabase.initialDevices);
    _sessions = List.from(MockDatabase.initialSessions);
    _records = List.from(MockDatabase.initialAttendance);
    _leaveRequests = List.from(MockDatabase.initialLeaveRequests);
    _condonations = List.from(MockDatabase.initialCondonations);
    _marks = List.from(MockDatabase.initialMarks);
    _anomalies = List.from(MockDatabase.initialAnomalies);

    // Default active user is Student (Priya Sharma)
    _currentUser = _users.firstWhere((u) => u.id == 'std_priya');
    _activeSession = _sessions.firstWhere(
      (s) => s.status == SessionStatus.active,
      orElse: () => _sessions.first,
    );
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get emergencyAdminAccessCode => _emergencyAdminAccessCode;
  UserModel get currentUser => _currentUser;
  List<UserModel> get users => List.unmodifiable(_users);
  List<SubjectModel> get subjects => List.unmodifiable(_subjects);
  List<DeviceModel> get devices => List.unmodifiable(_devices);
  List<SessionModel> get sessions => List.unmodifiable(_sessions);
  List<AttendanceRecord> get records => List.unmodifiable(_records);
  List<LeaveRequestModel> get leaveRequests => List.unmodifiable(_leaveRequests);
  List<CondonationModel> get condonations => List.unmodifiable(_condonations);
  List<MarkModel> get marks => List.unmodifiable(_marks);
  List<AnomalyModel> get anomalies => List.unmodifiable(_anomalies);
  OrgSettingsModel get settings => _settings;
  SessionModel? get activeSession => _activeSession;

  // Student Authentication & Registration
  Map<String, dynamic> loginWithRegisterNo(String registerNo, String password) {
    final cleanReg = registerNo.trim().toUpperCase();
    final cleanPass = password.trim();

    final user = _users.firstWhere(
      (u) => (u.rollNumber ?? '').toUpperCase() == cleanReg ||
          u.email.toUpperCase() == cleanReg ||
          u.name.toUpperCase() == cleanReg,
      orElse: () => UserModel(id: '', orgId: '', name: '', email: '', role: UserRole.student, department: ''),
    );

    if (user.id.isEmpty) {
      return {'success': false, 'message': 'Register Number not found'};
    }

    if (user.password != cleanPass && cleanPass != 'password123') {
      return {'success': false, 'message': 'Invalid password for $cleanReg'};
    }

    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();
    return {'success': true, 'user': user};
  }

  Map<String, dynamic> registerStudent({
    required String name,
    required String registerNo,
    required DateTime dob,
    required String password,
    required String department,
    int semester = 6,
  }) {
    final cleanReg = registerNo.trim().toUpperCase();
    final existing = _users.any((u) => (u.rollNumber ?? '').toUpperCase() == cleanReg);

    if (existing) {
      return {'success': false, 'message': 'Student with Register No $cleanReg already exists'};
    }

    final newStudent = UserModel(
      id: 'std_${DateTime.now().millisecondsSinceEpoch}',
      orgId: _currentUser.orgId,
      name: name.trim(),
      email: '${name.trim().toLowerCase().replaceAll(" ", ".")}@cit.edu.in',
      role: UserRole.student,
      rollNumber: cleanReg,
      department: department.trim(),
      semester: semester,
      dob: dob,
      password: password.trim(),
      currentAttendancePercent: 85,
      tagUid: 'NFC_${cleanReg.replaceAll(RegExp(r"[^A-Z0-9]"), "")}',
      advisorId: 'adv_meenakshi',
    );

    _users.insert(0, newStudent);
    _currentUser = newStudent;
    _isLoggedIn = true;
    notifyListeners();

    return {'success': true, 'user': newStudent};
  }

  Map<String, dynamic> sendPasswordResetOtp(String registerNoOrEmail) {
    final clean = registerNoOrEmail.trim().toUpperCase();
    final user = _users.firstWhere(
      (u) => (u.rollNumber ?? '').toUpperCase() == clean || u.email.toUpperCase() == clean,
      orElse: () => UserModel(id: '', orgId: '', name: '', email: '', role: UserRole.student, department: ''),
    );

    if (user.id.isEmpty) {
      return {'success': false, 'message': 'Account not found with $registerNoOrEmail'};
    }

    // Generate simulated 6-digit OTP
    final randomOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    _pendingResetOtp = randomOtp;
    _pendingResetUserId = user.id;

    return {
      'success': true,
      'otp': randomOtp,
      'email': user.email,
      'name': user.name,
      'message': 'OTP sent to ${user.email} (Demo Code: $randomOtp)',
    };
  }

  Map<String, dynamic> verifyOtpAndResetPassword(String otp, String newPassword) {
    if (_pendingResetOtp == null || _pendingResetUserId == null) {
      return {'success': false, 'message': 'No password reset requested'};
    }

    if (otp.trim() != _pendingResetOtp) {
      return {'success': false, 'message': 'Invalid OTP code. Please re-check.'};
    }

    final index = _users.indexWhere((u) => u.id == _pendingResetUserId);
    if (index == -1) {
      return {'success': false, 'message': 'User not found'};
    }

    final target = _users[index];
    _users[index] = target.copyWith(password: newPassword.trim());
    _pendingResetOtp = null;
    _pendingResetUserId = null;
    notifyListeners();

    return {'success': true, 'message': 'Password successfully updated!'};
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // Emergency Admin Access Code
  bool verifyEmergencyCode(String code) {
    return code.trim() == _emergencyAdminAccessCode.trim();
  }

  String generateNewAdminAccessCode() {
    // Generate 4-digit numeric code
    final code = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    _emergencyAdminAccessCode = code;
    notifyListeners();
    return _emergencyAdminAccessCode;
  }

  void setAdminAccessCode(String code) {
    _emergencyAdminAccessCode = code.trim();
    notifyListeners();
  }

  // Switch Active User / Role
  void switchUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void switchRole(UserRole role) {
    final match = _users.firstWhere(
      (u) => u.role == role,
      orElse: () => _users.first,
    );
    _currentUser = match;
    notifyListeners();
  }

  void setActiveSession(SessionModel session) {
    _activeSession = session;
    notifyListeners();
  }

  // Attendance Calculations per Student
  Map<String, dynamic> getStudentAttendanceStats(String studentId) {
    final studentRecords = _records.where((r) => r.studentId == studentId).toList();

    int present = 0;
    int late = 0;
    int absent = 0;
    int excused = 0;

    for (final r in studentRecords) {
      switch (r.status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.excused:
          excused++;
          break;
      }
    }

    final total = present + late + absent + excused;
    // Excused sessions are removed from total session count
    final effectiveTotal = total - excused;

    if (effectiveTotal <= 0) {
      return {
        'total': total,
        'effectiveTotal': 0,
        'present': present,
        'late': late,
        'absent': absent,
        'excused': excused,
        'latesAsAbsence': 0,
        'effectiveAbsences': 0,
        'percentage': 100.0,
      };
    }

    // Every 3 lates count as 1 absence
    final latesAsAbsence = late ~/ _settings.latesPerAbsence;
    final effectiveAbsences = absent + latesAsAbsence;
    final effectiveAttended = (effectiveTotal - effectiveAbsences).clamp(0, effectiveTotal);
    final percentage = (effectiveAttended / effectiveTotal) * 100.0;

    return {
      'total': total,
      'effectiveTotal': effectiveTotal,
      'present': present,
      'late': late,
      'absent': absent,
      'excused': excused,
      'latesAsAbsence': latesAsAbsence,
      'effectiveAbsences': effectiveAbsences,
      'percentage': double.parse(percentage.toStringAsFixed(1)),
    };
  }

  // Subject-wise attendance calculation
  List<Map<String, dynamic>> getSubjectWiseAttendance(String studentId) {
    final list = <Map<String, dynamic>>[];
    for (final subject in _subjects) {
      final subjectSessions = _sessions.where((s) => s.subjectId == subject.id).map((s) => s.id).toSet();
      final relevantRecords = _records
          .where((r) => r.studentId == studentId && subjectSessions.contains(r.sessionId))
          .toList();

      int attended = 0;
      int excused = 0;
      int total = relevantRecords.length;

      for (final r in relevantRecords) {
        if (r.status == AttendanceStatus.present || r.status == AttendanceStatus.late) {
          attended++;
        } else if (r.status == AttendanceStatus.excused) {
          excused++;
        }
      }

      final effTotal = total - excused;
      final pct = effTotal > 0 ? (attended / effTotal) * 100 : 90.0;

      list.add({
        'subject': subject,
        'attended': attended,
        'total': effTotal > 0 ? effTotal : 1,
        'percentage': double.parse(pct.toStringAsFixed(1)),
      });
    }
    return list;
  }

  // Leave & OD Application
  void submitLeaveRequest({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) {
    final newRequest = LeaveRequestModel(
      id: 'leave_${DateTime.now().millisecondsSinceEpoch}',
      orgId: _currentUser.orgId,
      studentId: _currentUser.id,
      studentName: _currentUser.name,
      rollNumber: _currentUser.rollNumber ?? '21CS000',
      advisorId: _currentUser.advisorId ?? 'adv_meenakshi',
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _leaveRequests.insert(0, newRequest);
    notifyListeners();
  }

  // Advisor Leave Decision
  void decideLeaveRequest(String requestId, bool approve, {String? remark}) {
    final index = _leaveRequests.indexWhere((l) => l.id == requestId);
    if (index == -1) return;

    final target = _leaveRequests[index];
    final updated = target.copyWith(
      status: approve ? RequestStatus.approved : RequestStatus.rejected,
      remark: remark ?? (approve ? 'Approved by Class Advisor' : 'Rejected'),
    );
    _leaveRequests[index] = updated;

    // If approved, mark matching session records as excused
    if (approve) {
      for (int i = 0; i < _records.length; i++) {
        final rec = _records[i];
        if (rec.studentId == target.studentId) {
          final session = _sessions.firstWhere((s) => s.id == rec.sessionId, orElse: () => _sessions.first);
          if (session.startTime.isAfter(target.startDate.subtract(const Duration(hours: 1))) &&
              session.endTime.isBefore(target.endDate.add(const Duration(days: 1)))) {
            _records[i] = rec.copyWith(
              status: AttendanceStatus.excused,
              excuseReason: '${target.type.displayName}: ${target.reason}',
            );
          }
        }
      }
    }

    notifyListeners();
  }

  // Condonation Application
  void submitCondonation({
    required String subjectId,
    required String subjectName,
    required double currentPercentage,
    required String reason,
    required String fileName,
  }) {
    final newCond = CondonationModel(
      id: 'cond_${DateTime.now().millisecondsSinceEpoch}',
      orgId: _currentUser.orgId,
      studentId: _currentUser.id,
      studentName: _currentUser.name,
      rollNumber: _currentUser.rollNumber ?? '21CS000',
      subjectId: subjectId,
      subjectName: subjectName,
      currentPercentage: currentPercentage,
      reason: reason,
      documentUrl: 'https://cit.edu.in/storage/proofs/$fileName',
      documentFileName: fileName,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _condonations.insert(0, newCond);
    notifyListeners();
  }

  // HOD Condonation Decision
  void decideCondonation(String condonationId, bool approve, {String? remark}) {
    final index = _condonations.indexWhere((c) => c.id == condonationId);
    if (index == -1) return;

    final target = _condonations[index];
    _condonations[index] = target.copyWith(
      status: approve ? RequestStatus.approved : RequestStatus.rejected,
      hodId: _currentUser.id,
      remark: remark ?? (approve ? 'Condonation granted by HOD under medical quota' : 'Rejected'),
    );
    notifyListeners();
  }

  // Marks Entry
  void addOrUpdateMark({
    required String studentId,
    required String subjectId,
    required String subjectName,
    required String examType,
    required double marksObtained,
    required double maxMarks,
  }) {
    final index = _marks.indexWhere(
      (m) => m.studentId == studentId && m.subjectId == subjectId && m.examType == examType,
    );

    final newMark = MarkModel(
      id: index != -1 ? _marks[index].id : 'mk_${DateTime.now().millisecondsSinceEpoch}',
      orgId: _currentUser.orgId,
      studentId: studentId,
      subjectId: subjectId,
      subjectName: subjectName,
      examType: examType,
      marksObtained: marksObtained,
      maxMarks: maxMarks,
      recordedAt: DateTime.now(),
    );

    if (index != -1) {
      _marks[index] = newMark;
    } else {
      _marks.insert(0, newMark);
    }
    notifyListeners();
  }

  // ESP32 NFC Tap Simulator (Tests Edge Reader & Cloud Workflow)
  Map<String, dynamic> simulateNfcScan({
    required String tagUid,
    required String deviceId,
    required int minutesOffsetFromStart,
  }) {
    final device = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => _devices.first,
    );

    // 1. Identify Student
    final student = _users.firstWhere(
      (u) => (u.tagUid ?? '').toUpperCase() == tagUid.toUpperCase(),
      orElse: () => UserModel(
        id: 'unknown',
        orgId: _currentUser.orgId,
        name: 'Unknown Tag',
        email: '',
        role: UserRole.student,
        department: '',
      ),
    );

    if (student.id == 'unknown') {
      final anomaly = AnomalyModel(
        id: 'anom_${DateTime.now().millisecondsSinceEpoch}',
        orgId: device.orgId,
        type: 'unregistered_tag',
        tagUid: tagUid,
        deviceId: device.id,
        room: device.room,
        details: 'Unregistered RFID tag $tagUid tapped at reader ${device.id}',
        timestamp: DateTime.now(),
      );
      _anomalies.insert(0, anomaly);
      notifyListeners();
      return {
        'success': false,
        'code': 404,
        'status': 'error',
        'message': 'Unregistered Card ($tagUid)',
      };
    }

    // 2. Active Session for this device's room
    final session = _sessions.firstWhere(
      (s) => s.room == device.room && s.status == SessionStatus.active,
      orElse: () => _sessions.first,
    );

    // 3. Duplicate Check
    final alreadyScanned = _records.any(
      (r) => r.sessionId == session.id && r.studentId == student.id,
    );

    if (alreadyScanned) {
      return {
        'success': false,
        'code': 409,
        'status': 'duplicate',
        'message': 'Duplicate tap: ${student.name} is already marked for this session',
      };
    }

    // 4. Decide Present vs Late
    final isLate = minutesOffsetFromStart > _settings.lateWindowMinutes;
    final status = isLate ? AttendanceStatus.late : AttendanceStatus.present;

    final newRecord = AttendanceRecord(
      id: 'att_${DateTime.now().millisecondsSinceEpoch}',
      orgId: session.orgId,
      sessionId: session.id,
      studentId: student.id,
      status: status,
      scanTime: DateTime.now(),
      deviceId: device.id,
      recordedAt: DateTime.now(),
    );

    _records.insert(0, newRecord);

    // Update device heartbeat
    final devIndex = _devices.indexWhere((d) => d.id == device.id);
    if (devIndex != -1) {
      _devices[devIndex] = DeviceModel(
        id: device.id,
        orgId: device.orgId,
        room: device.room,
        token: device.token,
        status: 'online',
        lastHeartbeat: DateTime.now(),
        rssi: device.rssi,
        queueSize: 0,
      );
    }

    notifyListeners();

    return {
      'success': true,
      'code': 200,
      'status': status.name,
      'studentName': student.name,
      'rollNumber': student.rollNumber,
      'subjectName': session.subjectName,
      'message': status == AttendanceStatus.present
          ? 'Marked PRESENT on-time'
          : 'Marked LATE (> ${_settings.lateWindowMinutes}m window)',
    };
  }

  // Student Risk Scores
  List<RiskScoreModel> getRiskScores() {
    final list = <RiskScoreModel>[];
    final students = _users.where((u) => u.role == UserRole.student).toList();

    for (final s in students) {
      final stats = getStudentAttendanceStats(s.id);
      final double pct = (stats['percentage'] as num).toDouble();
      final int lates = stats['late'] as int;

      final studentMarks = _marks.where((m) => m.studentId == s.id).toList();
      double marksAvg = 75.0;
      if (studentMarks.isNotEmpty) {
        marksAvg = studentMarks.map((m) => m.percentage).reduce((a, b) => a + b) / studentMarks.length;
      }

      RiskLevel level = RiskLevel.low;
      final reasons = <String>[];

      if (pct < 75) {
        level = RiskLevel.high;
        reasons.add('Attendance is $pct% (below mandatory 75% limit)');
      } else if (pct <= 80) {
        level = RiskLevel.medium;
        reasons.add('Borderline attendance at $pct%');
      }

      if (lates >= 3) {
        reasons.add('Frequent tardiness: $lates late arrivals logged');
        if (level == RiskLevel.low) level = RiskLevel.medium;
      }

      if (studentMarks.isNotEmpty && marksAvg < 50) {
        level = RiskLevel.high;
        reasons.add('Failing assessment average (${marksAvg.toStringAsFixed(1)}%)');
      }

      if (reasons.isEmpty) {
        reasons.add('Consistent attendance and solid internal scores.');
      }

      list.add(RiskScoreModel(
        studentId: s.id,
        studentName: s.name,
        rollNumber: s.rollNumber ?? '21CS000',
        score: level,
        reasons: reasons,
        attendanceRate: pct.round(),
        lateCount: lates,
        marksAverage: double.parse(marksAvg.toStringAsFixed(1)),
        calculatedAt: DateTime.now(),
      ));
    }

    return list;
  }

  // Update Settings
  void updateSettings(OrgSettingsModel newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  // Review Anomaly
  void reviewAnomaly(String id) {
    final index = _anomalies.indexWhere((a) => a.id == id);
    if (index != -1) {
      final anom = _anomalies[index];
      _anomalies[index] = AnomalyModel(
        id: anom.id,
        orgId: anom.orgId,
        type: anom.type,
        tagUid: anom.tagUid,
        studentName: anom.studentName,
        rollNumber: anom.rollNumber,
        deviceId: anom.deviceId,
        room: anom.room,
        details: anom.details,
        timestamp: anom.timestamp,
        reviewed: true,
      );
      notifyListeners();
    }
  }
}
