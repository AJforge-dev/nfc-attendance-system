export type Role = 'student' | 'faculty' | 'advisor' | 'hod' | 'admin';

export type AttendanceStatus = 'present' | 'late' | 'absent' | 'excused';

export interface User {
  id: string;
  orgId: string;
  name: string;
  email: string;
  role: Role;
  department: string;
  tagUid?: string;
  rollNumber?: string;
  advisorId?: string;
  fcmToken?: string;
  lastAlertLevel?: number; // 80 | 75 | 70
}

export interface Device {
  id: string;
  orgId: string;
  room: string;
  token: string;
  lastHeartbeat?: number;
  rssi?: number;
  uptimeSec?: number;
  queueSize?: number;
  status: 'online' | 'offline';
}

export interface Session {
  id: string;
  orgId: string;
  subjectId: string;
  subjectName: string;
  facultyId: string;
  room: string;
  date: string; // YYYY-MM-DD
  startTime: number; // Unix epoch ms
  endTime: number; // Unix epoch ms
  status: 'scheduled' | 'active' | 'completed';
}

export interface AttendanceRecord {
  id: string;
  orgId: string;
  sessionId: string;
  studentId: string;
  status: AttendanceStatus;
  scanTime?: number;
  deviceId?: string;
  recordedAt: number;
}

export interface OrgSettings {
  lateWindowMinutes: number; // default: 10
  attendanceLimit: number; // default: 75%
  alertLevels: number[]; // [80, 75, 70]
  latesPerAbsence: number; // default: 3
}

export interface LeaveRequest {
  id: string;
  orgId: string;
  studentId: string;
  advisorId: string;
  type: 'leave' | 'od';
  startDate: string;
  endDate: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  remark?: string;
  createdAt: number;
}

export interface Condonation {
  id: string;
  orgId: string;
  studentId: string;
  subjectId: string;
  reason: string;
  documentUrl: string;
  status: 'pending' | 'approved' | 'rejected';
  hodId?: string;
  remark?: string;
  createdAt: number;
}

export interface Anomaly {
  id: string;
  orgId: string;
  type: 'rapid_scans' | 'odd_hours' | 'wrong_room' | 'duplicate_scan';
  tagUid: string;
  studentId?: string;
  deviceId: string;
  details: string;
  timestamp: number;
  reviewed: boolean;
}

export interface RiskScore {
  studentId: string;
  orgId: string;
  score: 'low' | 'medium' | 'high';
  reasons: string[];
  attendanceRate: number;
  lateCount: number;
  marksAverage: number;
  calculatedAt: number;
}
