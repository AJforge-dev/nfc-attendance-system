class MarkModel {
  final String id;
  final String orgId;
  final String studentId;
  final String subjectId;
  final String subjectName;
  final String examType; // 'Internal 1', 'Internal 2', 'Model Exam'
  final double marksObtained;
  final double maxMarks;
  final DateTime recordedAt;

  MarkModel({
    required this.id,
    required this.orgId,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    required this.examType,
    required this.marksObtained,
    required this.maxMarks,
    required this.recordedAt,
  });

  double get percentage => maxMarks > 0 ? (marksObtained / maxMarks) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orgId': orgId,
      'studentId': studentId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examType': examType,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
    };
  }

  factory MarkModel.fromMap(Map<String, dynamic> map) {
    return MarkModel(
      id: map['id'] ?? '',
      orgId: map['orgId'] ?? '',
      studentId: map['studentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      examType: map['examType'] ?? 'Internal 1',
      marksObtained: (map['marksObtained'] ?? 0.0).toDouble(),
      maxMarks: (map['maxMarks'] ?? 100.0).toDouble(),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        map['recordedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
