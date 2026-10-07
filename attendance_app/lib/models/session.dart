enum SessionStatus {
  scheduled,
  active,
  completed;

  String get displayName {
    switch (this) {
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.active:
        return 'In Progress (Active)';
      case SessionStatus.completed:
        return 'Completed';
    }
  }
}

class SessionModel {
  final String id;
  final String orgId;
  final String subjectId;
  final String subjectCode;
  final String subjectName;
  final String facultyId;
  final String facultyName;
  final String room;
  final DateTime startTime;
  final DateTime endTime;
  final SessionStatus status;

  SessionModel({
    required this.id,
    required this.orgId,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.facultyId,
    required this.facultyName,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'subjectId': subjectId,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'room': room,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectCode: map['subjectCode'] ?? '',
      subjectName: map['subjectName'] ?? '',
      facultyId: map['facultyId'] ?? '',
      facultyName: map['facultyName'] ?? '',
      room: map['room'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(
        map['startTime'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        map['endTime'] ??
            DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      ),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'scheduled'),
        orElse: () => SessionStatus.scheduled,
      ),
    );
  }
}

class SubjectModel {
  final String id;
  final String orgId;
  final String code;
  final String name;
  final String department;
  final String facultyId;
  final String facultyName;

  SubjectModel({
    required this.id,
    required this.orgId,
    required this.code,
    required this.name,
    required this.department,
    required this.facultyId,
    required this.facultyName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'code': code,
      'name': name,
      'department': department,
      'facultyId': facultyId,
      'facultyName': facultyName,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      facultyId: map['facultyId'] ?? '',
      facultyName: map['facultyName'] ?? '',
    );
  }
}
