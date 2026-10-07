import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { AttendanceRecord, LeaveRequest, OrgSettings, User } from './types';

const db = admin.firestore();

/**
 * Trigger: When an Advisor approves a Leave or OD request
 * Marks affected sessions as 'excused' and recalculates student attendance
 */
export const onLeaveDecisionTrigger = functions.firestore
  .document('leaveRequests/{requestId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data() as LeaveRequest;
    const afterData = change.after.data() as LeaveRequest;

    // Only run if status transitioned to approved
    if (beforeData.status !== 'approved' && afterData.status === 'approved') {
      const studentId = afterData.studentId;
      const orgId = afterData.orgId;
      const startMs = new Date(afterData.startDate).getTime();
      const endMs = new Date(afterData.endDate).getTime() + 86400000; // End of day

      console.log(`Processing approved leave for student ${studentId} from ${afterData.startDate} to ${afterData.endDate}`);

      // 1. Find all sessions in this date range
      const sessionsSnapshot = await db.collection('sessions')
        .where('orgId', '==', orgId)
        .where('startTime', '>=', startMs)
        .where('startTime', '<=', endMs)
        .get();

      const batch = db.batch();

      for (const sessionDoc of sessionsSnapshot.docs) {
        const sessionId = sessionDoc.id;

        // Check if attendance record already exists
        const attQuery = await db.collection('attendance')
          .where('sessionId', '==', sessionId)
          .where('studentId', '==', studentId)
          .limit(1)
          .get();

        if (!attQuery.empty) {
          // Update status to excused
          batch.update(attQuery.docs[0].ref, {
            status: 'excused',
            excuseReason: afterData.type.toUpperCase() + ': ' + afterData.reason
          });
        } else {
          // Create excused record
          const newAttRef = db.collection('attendance').doc();
          const excusedRecord: Omit<AttendanceRecord, 'id'> = {
            orgId,
            sessionId,
            studentId,
            status: 'excused',
            recordedAt: Date.now()
          };
          batch.set(newAttRef, excusedRecord);
        }
      }

      await batch.commit();

      // 2. Create notification alert for student
      await db.collection('alerts').add({
        orgId,
        userId: studentId,
        title: `${afterData.type.toUpperCase()} Request Approved`,
        message: `Your ${afterData.type === 'od' ? 'On-Duty' : 'Leave'} for ${afterData.startDate} to ${afterData.endDate} has been approved by your advisor.`,
        type: 'leave_approved',
        level: 'info',
        createdAt: Date.now(),
        read: false
      });
    }
  });

/**
 * Trigger: When an Attendance record is created or updated
 * Recalculates student's attendance percentage and creates warning alerts
 * if percentage drops below 80%, 75%, or 70%.
 */
export const onAttendanceChangeTrigger = functions.firestore
  .document('attendance/{attendanceId}')
  .onWrite(async (change, context) => {
    const afterData = change.after.exists ? (change.after.data() as AttendanceRecord) : null;
    if (!afterData) return;

    const studentId = afterData.studentId;
    const orgId = afterData.orgId;

    try {
      // 1. Fetch all attendance records for this student
      const studentAttDocs = await db.collection('attendance')
        .where('orgId', '==', orgId)
        .where('studentId', '==', studentId)
        .get();

      let presentCount = 0;
      let lateCount = 0;
      let absentCount = 0;
      let excusedCount = 0;

      studentAttDocs.forEach(doc => {
        const att = doc.data() as AttendanceRecord;
        if (att.status === 'present') presentCount++;
        else if (att.status === 'late') lateCount++;
        else if (att.status === 'absent') absentCount++;
        else if (att.status === 'excused') excusedCount++;
      });

      const totalRecorded = presentCount + lateCount + absentCount + excusedCount;
      // Formula per specification:
      // Excused sessions are removed from total session count
      const effectiveTotal = totalRecorded - excusedCount;
      if (effectiveTotal <= 0) return;

      // 3 lates count as 1 absence
      const latesAsAbsence = Math.floor(lateCount / 3);
      const effectiveAbsences = absentCount + latesAsAbsence;
      const effectiveAttended = Math.max(0, effectiveTotal - effectiveAbsences);
      const attendancePercentage = Math.round((effectiveAttended / effectiveTotal) * 100);

      // 2. Fetch student profile to check previous alert level
      const userRef = db.collection('users').doc(studentId);
      const userDoc = await userRef.get();
      if (!userDoc.exists) return;
      const userData = userDoc.data() as User;

      const previousAlertLevel = userData.lastAlertLevel ?? 100;
      let newAlertLevel: number | null = null;
      let alertMessage = '';

      if (attendancePercentage <= 70 && previousAlertLevel > 70) {
        newAlertLevel = 70;
        alertMessage = `CRITICAL: Your attendance has dropped to ${attendancePercentage}%. You are below 70% and required to submit a Condonation request to the HOD.`;
      } else if (attendancePercentage <= 75 && previousAlertLevel > 75) {
        newAlertLevel = 75;
        alertMessage = `WARNING: Your attendance has fallen below 75% (${attendancePercentage}%). You risk being debarred from semester exams unless improved.`;
      } else if (attendancePercentage <= 80 && previousAlertLevel > 80) {
        newAlertLevel = 80;
        alertMessage = `ATTENTION: Your attendance has reached ${attendancePercentage}%. Maintain regularity to keep above the 75% college requirement.`;
      }

      // If an alert threshold was crossed, create alert and update user profile
      if (newAlertLevel !== null) {
        await db.collection('alerts').add({
          orgId,
          userId: studentId,
          title: `Attendance Alert: ${attendancePercentage}%`,
          message: alertMessage,
          type: 'attendance_warning',
          level: newAlertLevel <= 70 ? 'danger' : 'warning',
          createdAt: Date.now(),
          read: false
        });

        await userRef.update({
          lastAlertLevel: newAlertLevel,
          currentAttendancePercent: attendancePercentage
        });
      } else {
        await userRef.update({
          currentAttendancePercent: attendancePercentage
        });
      }

    } catch (err) {
      console.error('Error in onAttendanceChangeTrigger:', err);
    }
  });
