import * as admin from 'firebase-admin';
import { Request, Response } from 'express';
import { AttendanceRecord, AttendanceStatus, Device, OrgSettings, Session, User } from './types';

const db = admin.firestore();

export const recordScanHandler = async (req: Request, res: Response) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { tagUid, deviceId, timestamp, token } = req.body;

  if (!tagUid || !deviceId || !timestamp || !token) {
    return res.status(400).json({ error: 'Missing required parameters: tagUid, deviceId, timestamp, token' });
  }

  try {
    // 1. Authenticate Device
    const deviceDoc = await db.collection('devices').doc(deviceId).get();
    if (!deviceDoc.exists) {
      return res.status(401).json({ error: 'Device not recognized' });
    }
    const deviceData = deviceDoc.data() as Device;
    if (deviceData.token !== token) {
      return res.status(401).json({ error: 'Invalid device credentials' });
    }

    const orgId = deviceData.orgId;
    const room = deviceData.room;

    // Scan timestamp: if in seconds (ESP32 epoch), convert to ms
    const scanTimeMs = timestamp < 10000000000 ? timestamp * 1000 : timestamp;

    // 2. Identify Student by NFC Tag UID
    const userQuery = await db.collection('users')
      .where('orgId', '==', orgId)
      .where('tagUid', '==', tagUid.toUpperCase())
      .limit(1)
      .get();

    if (userQuery.empty) {
      // Flag anomaly: Unregistered card tap
      await db.collection('anomalies').add({
        orgId,
        type: 'odd_hours',
        tagUid: tagUid.toUpperCase(),
        deviceId,
        details: `Unregistered tag ${tagUid} tapped at device ${deviceId} in room ${room}`,
        timestamp: scanTimeMs,
        reviewed: false
      });
      return res.status(404).json({ error: 'Card UID not registered to any student' });
    }

    const studentDoc = userQuery.docs[0];
    const student = studentDoc.data() as User;
    const studentId = studentDoc.id;

    // 3. Find Active Class Session for this Room
    const sessionsQuery = await db.collection('sessions')
      .where('orgId', '==', orgId)
      .where('room', '==', room)
      .where('startTime', '<=', scanTimeMs)
      .get();

    // Filter for session covering this timestamp
    const activeSessions = sessionsQuery.docs
      .map(doc => ({ id: doc.id, ...(doc.data() as Session) }))
      .filter(s => scanTimeMs <= s.endTime);

    if (activeSessions.length === 0) {
      // Check if scan was outside regular class hours
      await db.collection('anomalies').add({
        orgId,
        type: 'odd_hours',
        tagUid: tagUid.toUpperCase(),
        studentId,
        deviceId,
        details: `Scan by ${student.name} in room ${room} with no active scheduled session`,
        timestamp: scanTimeMs,
        reviewed: false
      });
      return res.status(422).json({ error: 'No active session scheduled in this room at this time' });
    }

    const currentSession = activeSessions[0];

    // 4. Duplicate Check
    const existingAttendance = await db.collection('attendance')
      .where('sessionId', '==', currentSession.id)
      .where('studentId', '==', studentId)
      .limit(1)
      .get();

    if (!existingAttendance.empty) {
      return res.status(409).json({
        error: 'Attendance already recorded for this session',
        status: existingAttendance.docs[0].data().status
      });
    }

    // 5. Fetch Org Settings for Late Window
    const settingsDoc = await db.collection('orgs').doc(orgId).collection('settings').doc('config').get();
    const settings: OrgSettings = settingsDoc.exists 
      ? (settingsDoc.data() as OrgSettings) 
      : { lateWindowMinutes: 10, attendanceLimit: 75, alertLevels: [80, 75, 70], latesPerAbsence: 3 };

    const lateWindowMs = (settings.lateWindowMinutes || 10) * 60 * 1000;
    const isLate = scanTimeMs > (currentSession.startTime + lateWindowMs);
    const attendanceStatus: AttendanceStatus = isLate ? 'late' : 'present';

    // 6. Rapid Scan Anomaly Check (e.g., student scanned in another room within last 2 minutes)
    const recentScans = await db.collection('attendance')
      .where('studentId', '==', studentId)
      .where('scanTime', '>=', scanTimeMs - 120000)
      .get();

    if (!recentScans.empty) {
      await db.collection('anomalies').add({
        orgId,
        type: 'rapid_scans',
        tagUid: tagUid.toUpperCase(),
        studentId,
        deviceId,
        details: `Rapid repeat scan: ${student.name} scanned in two rooms within 2 minutes`,
        timestamp: scanTimeMs,
        reviewed: false
      });
    }

    // 7. Write Attendance Record
    const attendanceRecord: Omit<AttendanceRecord, 'id'> = {
      orgId,
      sessionId: currentSession.id,
      studentId,
      status: attendanceStatus,
      scanTime: scanTimeMs,
      deviceId,
      recordedAt: Date.now()
    };

    const newAttendanceRef = await db.collection('attendance').add(attendanceRecord);

    // Update Device Last Heartbeat & Activity
    await db.collection('devices').doc(deviceId).update({
      lastHeartbeat: Date.now(),
      status: 'online'
    });

    return res.status(200).json({
      success: true,
      attendanceId: newAttendanceRef.id,
      status: attendanceStatus,
      student: {
        id: studentId,
        name: student.name,
        rollNumber: student.rollNumber
      },
      session: {
        id: currentSession.id,
        subjectName: currentSession.subjectName,
        room: currentSession.room
      },
      message: attendanceStatus === 'present' ? 'Marked Present' : 'Marked Late (> 10m)'
    });

  } catch (error: any) {
    console.error('Error recording scan:', error);
    return res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
};
