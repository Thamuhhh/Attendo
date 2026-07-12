const admin = require('firebase-admin');
const config = require('../config');
const logger = require('../utils/logger');

let initialized = false;

function initializeFirebase() {
  if (initialized) return;
  if (!config.fcm.projectId || !config.fcm.privateKey || !config.fcm.clientEmail) {
    logger.warn('Firebase not configured, push notifications disabled');
    return;
  }
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: config.fcm.projectId,
        privateKey: config.fcm.privateKey,
        clientEmail: config.fcm.clientEmail,
      }),
    });
    initialized = true;
    logger.info('Firebase Admin initialized');
  } catch (err) {
    logger.error('Firebase init failed', { error: err.message });
  }
}

async function sendPushNotification(fcmToken, { title, body, data = {} }) {
  if (!initialized || !fcmToken) return null;
  try {
    const result = await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data,
    });
    logger.info('Push notification sent', { token: fcmToken.substring(0, 10) + '...', result });
    return result;
  } catch (err) {
    logger.error('Push notification failed', { error: err.message });
    if (err.code === 'messaging/registration-token-not-registered') {
      logger.warn('Invalid FCM token, should remove from DB');
    }
    throw err;
  }
}

async function sendBulkNotifications(tokens, { title, body, data = {} }) {
  if (!initialized || !tokens.length) return null;
  try {
    const message = {
      notification: { title, body },
      data,
      tokens: tokens.filter(Boolean),
    };
    const result = await admin.messaging().sendEachForMulticast(message);
    logger.info('Bulk push sent', { success: result.successCount, failed: result.failureCount });
    return result;
  } catch (err) {
    logger.error('Bulk push failed', { error: err.message });
    throw err;
  }
}

async function sendAttendanceNotification(inst, studentName, date, status) {
  if (!inst.fcmToken) return;
  return sendPushNotification(inst.fcmToken, {
    title: 'Attendance Update',
    body: `${studentName} marked ${status} on ${date}`,
    data: { type: 'attendance', date },
  });
}

async function sendFeeNotification(inst, studentName, month, year) {
  if (!inst.fcmToken) return;
  return sendPushNotification(inst.fcmToken, {
    title: 'Fee Reminder',
    body: `Fee pending for ${studentName} for ${month}/${year}`,
    data: { type: 'fee', month: String(month), year: String(year) },
  });
}

initializeFirebase();

module.exports = { sendPushNotification, sendBulkNotifications, sendAttendanceNotification, sendFeeNotification };
