enum AttendanceStatus {
  present,
  late,
  absent,
  excused;

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late (>10m)';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.excused:
        return 'Excused (OD/Leave)';
    }
  }
}

class AttendanceRecord {
  final String id;
  final String orgId;
  final String sessionId;
  final String studentId;
  final AttendanceStatus status;
  final DateTime? scanTime;
  final String? deviceId;
  final String? excuseReason;
  final DateTime recordedAt;

  AttendanceRecord({
    required this.id,
    required this.orgId,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.scanTime,
    this.deviceId,
    this.excuseReason,
    required this.recordedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? orgId,
    String? sessionId,
    String? studentId,
    AttendanceStatus? status,
    DateTime? scanTime,
    String? deviceId,
    String? excuseReason,
    DateTime? recordedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      scanTime: scanTime ?? this.scanTime,
      deviceId: deviceId ?? this.deviceId,
      excuseReason: excuseReason ?? this.excuseReason,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status.name,
      'scanTime': scanTime?.millisecondsSinceEpoch,
      'deviceId': deviceId,
      'excuseReason': excuseReason,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      studentId: map['studentId'] ?? '',
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'absent'),
        orElse: () => AttendanceStatus.absent,
      ),
      scanTime: map['scanTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scanTime'])
          : null,
      deviceId: map['deviceId'],
      excuseReason: map['excuseReason'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        map['recordedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
