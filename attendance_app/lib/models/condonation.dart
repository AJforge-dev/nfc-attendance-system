import 'leave_request.dart';

class CondonationModel {
  final String id;
  final String orgId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String subjectId;
  final String subjectName;
  final double currentPercentage;
  final String reason;
  final String documentUrl;
  final String documentFileName;
  final RequestStatus status;
  final String? hodId;
  final String? remark;
  final DateTime createdAt;

  CondonationModel({
    required this.id,
    required this.orgId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.subjectId,
    required this.subjectName,
    required this.currentPercentage,
    required this.reason,
    required this.documentUrl,
    required this.documentFileName,
    required this.status,
    this.hodId,
    this.remark,
    required this.createdAt,
  });

  CondonationModel copyWith({
    String? id,
    String? orgId,
    String? studentId,
    String? studentName,
    String? rollNumber,
    String? subjectId,
    String? subjectName,
    double? currentPercentage,
    String? reason,
    String? documentUrl,
    String? documentFileName,
    RequestStatus? status,
    String? hodId,
    String? remark,
    DateTime? createdAt,
  }) {
    return CondonationModel(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      currentPercentage: currentPercentage ?? this.currentPercentage,
      reason: reason ?? this.reason,
      documentUrl: documentUrl ?? this.documentUrl,
      documentFileName: documentFileName ?? this.documentFileName,
      status: status ?? this.status,
      hodId: hodId ?? this.hodId,
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
      'subjectId': subjectId,
      'subjectName': subjectName,
      'currentPercentage': currentPercentage,
      'reason': reason,
      'documentUrl': documentUrl,
      'documentFileName': documentFileName,
      'status': status.name,
      'hodId': hodId,
      'remark': remark,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CondonationModel.fromMap(Map<String, dynamic> map) {
    return CondonationModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      currentPercentage: (map['currentPercentage'] ?? 0.0).toDouble(),
      reason: map['reason'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      documentFileName: map['documentFileName'] ?? 'medical_certificate.pdf',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      hodId: map['hodId'],
      remark: map['remark'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
