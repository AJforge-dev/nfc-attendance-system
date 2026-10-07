enum UserRole {
  student,
  faculty,
  advisor,
  hod,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.hod:
        return 'HOD';
      case UserRole.admin:
        return 'Administrator';
    }
  }
}

class UserModel {
  final String id;
  final String orgId;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String? rollNumber; // Register Number
  final String? tagUid;
  final String? advisorId;
  final String? designation;
  final int? semester;
  final int? lastAlertLevel;
  final int currentAttendancePercent;
  final DateTime? dob;
  final String password;

  UserModel({
    required this.id,
    required this.orgId,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.rollNumber,
    this.tagUid,
    this.advisorId,
    this.designation,
    this.semester,
    this.lastAlertLevel,
    this.currentAttendancePercent = 85,
    this.dob,
    this.password = 'password123',
  });

  UserModel copyWith({
    String? id,
    String? orgId,
    String? name,
    String? email,
    UserRole? role,
    String? department,
    String? rollNumber,
    String? tagUid,
    String? advisorId,
    String? designation,
    int? semester,
    int? lastAlertLevel,
    int? currentAttendancePercent,
    DateTime? dob,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      rollNumber: rollNumber ?? this.rollNumber,
      tagUid: tagUid ?? this.tagUid,
      advisorId: advisorId ?? this.advisorId,
      designation: designation ?? this.designation,
      semester: semester ?? this.semester,
      lastAlertLevel: lastAlertLevel ?? this.lastAlertLevel,
      currentAttendancePercent:
          currentAttendancePercent ?? this.currentAttendancePercent,
      dob: dob ?? this.dob,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'name': name,
      'email': email,
      'role': role.name,
      'department': department,
      'rollNumber': rollNumber,
      'tagUid': tagUid,
      'advisorId': advisorId,
      'designation': designation,
      'semester': semester,
      'lastAlertLevel': lastAlertLevel,
      'currentAttendancePercent': currentAttendancePercent,
      'dob': dob?.millisecondsSinceEpoch,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'student'),
        orElse: () => UserRole.student,
      ),
      department: map['department'] ?? '',
      rollNumber: map['rollNumber'],
      tagUid: map['tagUid'],
      advisorId: map['advisorId'],
      designation: map['designation'],
      semester: map['semester'],
      lastAlertLevel: map['lastAlertLevel'],
      currentAttendancePercent: map['currentAttendancePercent'] ?? 85,
      dob: map['dob'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dob']) : null,
      password: map['password'] ?? 'password123',
    );
  }
}
