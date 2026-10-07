class DeviceModel {
  final String id;
  final String orgId;
  final String room;
  final String token;
  final String status; // 'online' | 'offline'
  final DateTime? lastHeartbeat;
  final int rssi;
  final int queueSize;

  DeviceModel({
    required this.id,
    required this.orgId,
    required this.room,
    required this.token,
    this.status = 'online',
    this.lastHeartbeat,
    this.rssi = -60,
    this.queueSize = 0,
  });

  bool get isOnline {
    if (lastHeartbeat == null) return false;
    return DateTime.now().difference(lastHeartbeat!).inMinutes < 3;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'room': room,
      'token': token,
      'status': status,
      'lastHeartbeat': lastHeartbeat?.millisecondsSinceEpoch,
      'rssi': rssi,
      'queueSize': queueSize,
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      room: map['room'] ?? '',
      token: map['token'] ?? '',
      status: map['status'] ?? 'offline',
      lastHeartbeat: map['lastHeartbeat'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastHeartbeat'])
          : null,
      rssi: map['rssi'] ?? -60,
      queueSize: map['queueSize'] ?? 0,
    );
  }
}

class AnomalyModel {
  final String id;
  final String orgId;
  final String type; // 'rapid_scans', 'odd_hours', 'wrong_room', 'unregistered_tag'
  final String tagUid;
  final String? studentName;
  final String? rollNumber;
  final String deviceId;
  final String room;
  final String details;
  final DateTime timestamp;
  final bool reviewed;

  AnomalyModel({
    required this.id,
    required this.orgId,
    required this.type,
    required this.tagUid,
    this.studentName,
    this.rollNumber,
    required this.deviceId,
    required this.room,
    required this.details,
    required this.timestamp,
    this.reviewed = false,
  });

  String get typeTitle {
    switch (type) {
      case 'rapid_scans':
        return 'Rapid Repeat Tap (< 60s)';
      case 'odd_hours':
        return 'Odd-Hours Access Tap';
      case 'wrong_room':
        return 'Wrong Classroom Tap';
      case 'unregistered_tag':
        return 'Unregistered Card Detected';
      default:
        return 'Suspicious Scan';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'type': type,
      'tagUid': tagUid,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'deviceId': deviceId,
      'room': room,
      'details': details,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reviewed': reviewed,
    };
  }

  factory AnomalyModel.fromMap(Map<String, dynamic> map) {
    return AnomalyModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      type: map['type'] ?? 'unknown',
      tagUid: map['tagUid'] ?? '',
      studentName: map['studentName'],
      rollNumber: map['rollNumber'],
      deviceId: map['deviceId'] ?? '',
      room: map['room'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      reviewed: map['reviewed'] ?? false,
    );
  }
}

enum RiskLevel {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }
}

class RiskScoreModel {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final RiskLevel score;
  final List<String> reasons;
  final int attendanceRate;
  final int lateCount;
  final double marksAverage;
  final DateTime calculatedAt;

  RiskScoreModel({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.score,
    required this.reasons,
    required this.attendanceRate,
    required this.lateCount,
    required this.marksAverage,
    required this.calculatedAt,
  });
}

class OrgSettingsModel {
  final int lateWindowMinutes;
  final int attendanceLimit;
  final List<int> alertLevels;
  final int latesPerAbsence;

  OrgSettingsModel({
    this.lateWindowMinutes = 10,
    this.attendanceLimit = 75,
    this.alertLevels = const [80, 75, 70],
    this.latesPerAbsence = 3,
  });

  OrgSettingsModel copyWith({
    int? lateWindowMinutes,
    int? attendanceLimit,
    List<int>? alertLevels,
    int? latesPerAbsence,
  }) {
    return OrgSettingsModel(
      lateWindowMinutes: lateWindowMinutes ?? this.lateWindowMinutes,
      attendanceLimit: attendanceLimit ?? this.attendanceLimit,
      alertLevels: alertLevels ?? this.alertLevels,
      latesPerAbsence: latesPerAbsence ?? this.latesPerAbsence,
    );
  }
}
