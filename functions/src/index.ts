import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

import { recordScanHandler } from './recordScan';
import { deviceHeartbeatHandler } from './deviceHeartbeat';
import { onLeaveDecisionTrigger, onAttendanceChangeTrigger } from './triggers';
import { evaluateAllStudentsRisk } from './riskModel';
import { chatbotHandler } from './chatbot';

// HTTPS Endpoints for ESP32 Edge Readers
export const recordScan = functions.https.onRequest(recordScanHandler);
export const deviceHeartbeat = functions.https.onRequest(deviceHeartbeatHandler);

// Background Firestore Triggers
export const onLeaveDecision = onLeaveDecisionTrigger;
export const onAttendanceChange = onAttendanceChangeTrigger;

// AI Chatbot Endpoint (Tamil + English)
export const aiChatbot = functions.https.onRequest(chatbotHandler);

// Daily Nightly Scheduled Risk Engine
export const scheduledRiskEvaluation = functions.pubsub
  .schedule('0 0 * * *') // Midnight daily
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    console.log('Running nightly student risk evaluation...');
    const orgs = await admin.firestore().collection('orgs').get();
    for (const org of orgs.docs) {
      await evaluateAllStudentsRisk(org.id);
    }
    console.log('Nightly risk evaluation completed.');
  });
