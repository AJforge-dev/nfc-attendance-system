enum LeaveType {
  leave,
  od;

  String get displayName {
    switch (this) {
      case LeaveType.leave:
        return 'Personal / Medical Leave';
      case LeaveType.od:
        return 'On-Duty (Symposium / Sports)';
    }
  }
}

enum RequestStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending Review';
      case RequestStatus.approved:
        return 'Approved (Excused)';
      case RequestStatus.rejected:
        return 'Rejected';
    }
  }
}

class LeaveRequestModel {
  final String id;
  final String orgId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String advisorId;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final RequestStatus status;
  final String? remark;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.orgId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.advisorId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.remark,
    required this.createdAt,
  });

  LeaveRequestModel copyWith({
    String? id,
    String? orgId,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? advisorId,
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    RequestStatus? status,
    String? remark,
    DateTime? createdAt,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      advisorId: advisorId ?? this.advisorId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'advisorId': advisorId,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'status': status.name,
      'remark': remark,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      advisorId: map['advisorId'] ?? '',
      type: LeaveType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'leave'),
        orElse: () => LeaveType.leave,
      ),
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      reason: map['reason'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      remark: map['remark'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
