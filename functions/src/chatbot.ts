import * as admin from 'firebase-admin';
import { Request, Response } from 'express';
import { GoogleGenAI } from '@google/genai';
import { AttendanceRecord, LeaveRequest, User } from './types';

const db = admin.firestore();

// AI Tools definitions
async function getStudentAttendanceSummary(studentId: string) {
  const attDocs = await db.collection('attendance').where('studentId', '==', studentId).get();
  let present = 0, late = 0, absent = 0, excused = 0;
  attDocs.forEach(d => {
    const s = d.data().status;
    if (s === 'present') present++;
    else if (s === 'late') late++;
    else if (s === 'absent') absent++;
    else if (s === 'excused') excused++;
  });
  const total = present + late + absent + excused;
  const effectiveTotal = Math.max(1, total - excused);
  const latesAsAbsence = Math.floor(late / 3);
  const effectiveAbsences = absent + latesAsAbsence;
  const effectiveAttended = Math.max(0, effectiveTotal - effectiveAbsences);
  const percentage = total > 0 ? Math.round((effectiveAttended / effectiveTotal) * 100) : 100;

  return {
    totalSessions: total,
    excusedSessions: excused,
    presentCount: present,
    lateCount: late,
    absentCount: absent,
    effectivePercentage: percentage,
    isBelowThreshold: percentage < 75
  };
}

async function getStudentMarksSummary(studentId: string) {
  const docs = await db.collection('marks').where('studentId', '==', studentId).get();
  return docs.docs.map(d => d.data());
}

async function getStudentLeaveStatus(studentId: string) {
  const docs = await db.collection('leaveRequests').where('studentId', '==', studentId).get();
  return docs.docs.map(d => {
    const l = d.data() as LeaveRequest;
    return {
      type: l.type,
      startDate: l.startDate,
      endDate: l.endDate,
      status: l.status,
      reason: l.reason,
      remark: l.remark
    };
  });
}

export const chatbotHandler = async (req: Request, res: Response) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { studentId, message, language = 'en' } = req.body;

  if (!studentId || !message) {
    return res.status(400).json({ error: 'studentId and message are required' });
  }

  try {
    const studentDoc = await db.collection('users').doc(studentId).get();
    if (!studentDoc.exists) {
      return res.status(404).json({ error: 'Student not found' });
    }
    const student = studentDoc.data() as User;

    // Fetch student's real-time context
    const [attendanceInfo, marksInfo, leavesInfo] = await Promise.all([
      getStudentAttendanceSummary(studentId),
      getStudentMarksSummary(studentId),
      getStudentLeaveStatus(studentId)
    ]);

    // Check Gemini API Key
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      // Graceful fallback response when API key is not yet set
      const isTamil = language === 'ta' || /[஀-௿]/.test(message);
      if (message.toLowerCase().includes('attendance') || message.includes('வருகை')) {
        const reply = isTamil
          ? `வணக்கம் ${student.name}. உங்கள் தற்போதைய வருகைப் பதிவு ${attendanceInfo.effectivePercentage}% ஆகும். வருகை: ${attendanceInfo.presentCount}, தாமதம்: ${attendanceInfo.lateCount}, விடுப்பு: ${attendanceInfo.absentCount}, விலக்கு: ${attendanceInfo.excusedSessions}.`
          : `Hello ${student.name}. Your overall attendance is currently ${attendanceInfo.effectivePercentage}%. (Present: ${attendanceInfo.presentCount}, Late: ${attendanceInfo.lateCount}, Absent: ${attendanceInfo.absentCount}, Excused: ${attendanceInfo.excusedSessions}). Every 3 late scans count as 1 absence.`;
        return res.status(200).json({ reply, data: attendanceInfo });
      }

      const defaultReply = isTamil
        ? `வணக்கம் ${student.name}. நான் உங்கள் கல்வி உதவியாளர். வருகை விவரங்கள், விடுப்பு விண்ணப்பம் அல்லது மதிப்பெண்கள் பற்றி நீங்கள் கேட்கலாம்.`
        : `Hello ${student.name}. I am your Campus AI Assistant. You can ask me about your attendance percentage, leave status, or internal marks in English or தமிழ்.`;
      return res.status(200).json({ reply: defaultReply });
    }

    const ai = new GoogleGenAI({ apiKey });

    const systemPrompt = `You are the bilingual AI Assistant for the NFC Attendance System for colleges.
You assist student ${student.name} (Roll Number: ${student.rollNumber || 'N/A'}, Department: ${student.department || 'N/A'}).
You are fluent in both English and Tamil (தமிழ்).
Always reply in the language the student asks in (if Tamil, reply in clear, polite Tamil; if English, reply in English).

Current real-time data for ${student.name}:
- Attendance percentage: ${attendanceInfo.effectivePercentage}%
- Present count: ${attendanceInfo.presentCount}
- Late count: ${attendanceInfo.lateCount} (Note: 3 lates = 1 absence)
- Absent count: ${attendanceInfo.absentCount}
- Excused sessions (Approved Leave/OD): ${attendanceInfo.excusedSessions}
- Below 75% limit: ${attendanceInfo.isBelowThreshold ? 'YES (Condonation required if semester ends)' : 'NO'}
- Recent Leave/OD records: ${JSON.stringify(leavesInfo)}
- Recent Marks: ${JSON.stringify(marksInfo)}

Rules:
1. Provide accurate numbers from the data.
2. If attendance is below 75%, advise them on applying for condonation with medical certificates or meeting the HOD.
3. Be encouraging and concise.`;

    const response = await ai.models.generateContent({
      model: 'gemini-1.5-flash',
      contents: [
        { role: 'user', parts: [{ text: `${systemPrompt}\n\nStudent question: ${message}` }] }
      ]
    });

    const reply = response.text || 'I could not process your query at this moment.';
    return res.status(200).json({ reply, attendance: attendanceInfo });

  } catch (error: any) {
    console.error('Chatbot error:', error);
    return res.status(500).json({ error: error.message });
  }
};
