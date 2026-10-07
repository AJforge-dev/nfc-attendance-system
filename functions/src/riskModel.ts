import * as admin from 'firebase-admin';
import { AttendanceRecord, RiskScore, User } from './types';

const db = admin.firestore();

export async function calculateStudentRisk(studentId: string, orgId: string): Promise<RiskScore> {
  // 1. Fetch Attendance Records
  const attDocs = await db.collection('attendance')
    .where('orgId', '==', orgId)
    .where('studentId', '==', studentId)
    .get();

  let present = 0;
  let late = 0;
  let absent = 0;
  let excused = 0;

  attDocs.forEach(d => {
    const data = d.data() as AttendanceRecord;
    if (data.status === 'present') present++;
    else if (data.status === 'late') late++;
    else if (data.status === 'absent') absent++;
    else if (data.status === 'excused') excused++;
  });

  const total = present + late + absent + excused;
  const effectiveTotal = Math.max(1, total - excused);
  const latesAsAbsence = Math.floor(late / 3);
  const effectiveAttended = Math.max(0, effectiveTotal - (absent + latesAsAbsence));
  const attendanceRate = total > 0 ? Math.round((effectiveAttended / effectiveTotal) * 100) : 100;

  // 2. Fetch Internal Marks
  const marksDocs = await db.collection('marks')
    .where('orgId', '==', orgId)
    .where('studentId', '==', studentId)
    .get();

  let marksSum = 0;
  let marksCount = 0;
  marksDocs.forEach(d => {
    const m = d.data();
    if (typeof m.marksObtained === 'number' && typeof m.maxMarks === 'number' && m.maxMarks > 0) {
      marksSum += (m.marksObtained / m.maxMarks) * 100;
      marksCount++;
    }
  });

  const marksAverage = marksCount > 0 ? Math.round(marksSum / marksCount) : 75;

  // 3. Compute Risk Category and Specific Reasons
  const reasons: string[] = [];
  let riskScore: 'low' | 'medium' | 'high' = 'low';

  if (attendanceRate < 75) {
    riskScore = 'high';
    reasons.push(`Attendance is ${attendanceRate}%, strictly below the mandatory 75% limit.`);
  } else if (attendanceRate <= 80) {
    riskScore = 'medium';
    reasons.push(`Attendance is borderline at ${attendanceRate}%.`);
  }

  if (late >= 4) {
    reasons.push(`High late frequency: accumulated ${late} late arrivals (converted to ${latesAsAbsence} absences).`);
    if (riskScore === 'low') riskScore = 'medium';
  }

  if (marksCount > 0 && marksAverage < 50) {
    reasons.push(`Failing internal assessment average (${marksAverage}%). High academic risk.`);
    riskScore = 'high';
  } else if (marksCount > 0 && marksAverage < 65) {
    reasons.push(`Moderate internal assessment average (${marksAverage}%).`);
    if (riskScore === 'low') riskScore = 'medium';
  }

  if (reasons.length === 0) {
    reasons.push('Consistent attendance (> 80%) and satisfactory academic performance.');
  }

  const result: RiskScore = {
    studentId,
    orgId,
    score: riskScore,
    reasons,
    attendanceRate,
    lateCount: late,
    marksAverage,
    calculatedAt: Date.now()
  };

  // Upsert into riskScores collection
  await db.collection('riskScores').doc(studentId).set(result);
  return result;
}

/**
 * Batch evaluates all enrolled students in the organization
 */
export async function evaluateAllStudentsRisk(orgId: string) {
  const studentsSnapshot = await db.collection('users')
    .where('orgId', '==', orgId)
    .where('role', '==', 'student')
    .get();

  const results: RiskScore[] = [];
  for (const doc of studentsSnapshot.docs) {
    const risk = await calculateStudentRisk(doc.id, orgId);
    results.push(risk);
  }
  return results;
}
