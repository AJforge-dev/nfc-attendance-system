import * as admin from 'firebase-admin';
import { Request, Response } from 'express';
import { Device } from './types';

const db = admin.firestore();

export const deviceHeartbeatHandler = async (req: Request, res: Response) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { deviceId, token, rssi, uptimeSec, queueSize, freeHeap } = req.body;

  if (!deviceId || !token) {
    return res.status(400).json({ error: 'Missing deviceId or token' });
  }

  try {
    const deviceRef = db.collection('devices').doc(deviceId);
    const deviceDoc = await deviceRef.get();

    if (!deviceDoc.exists) {
      return res.status(401).json({ error: 'Device not registered' });
    }

    const deviceData = deviceDoc.data() as Device;
    if (deviceData.token !== token) {
      return res.status(401).json({ error: 'Unauthorized device token' });
    }

    await deviceRef.update({
      lastHeartbeat: Date.now(),
      status: 'online',
      rssi: rssi ?? null,
      uptimeSec: uptimeSec ?? null,
      queueSize: queueSize ?? 0,
      freeHeap: freeHeap ?? null
    });

    return res.status(200).json({
      success: true,
      serverTime: Date.now(),
      message: 'Heartbeat acknowledged'
    });
  } catch (error: any) {
    console.error('Heartbeat error:', error);
    return res.status(500).json({ error: error.message });
  }
};
