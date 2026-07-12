const mongoose = require('mongoose');
const config = require('./config');
const { sendPushNotification } = require('./utils/pushService');
const Institution = require('./models/Institution');

async function test() {
  await mongoose.connect(config.mongoUri);
  console.log('MongoDB connected');

  const inst = await Institution.findOne({});
  if (!inst) { console.log('No institution found'); process.exit(1); }
  console.log('Institution:', inst.name);
  console.log('FCM Token:', inst.fcmToken ? inst.fcmToken.substring(0, 50) + '...' : 'NULL');

  if (!inst.fcmToken) {
    console.log('\nNo FCM token. Flutter app la re-login pannu, notification permission kudukkunga.');
    process.exit(0);
  }

  try {
    const result = await sendPushNotification(inst.fcmToken, {
      title: 'Attendo Test',
      body: 'Push notification working!',
      data: { type: 'test' },
    });
    console.log('SUCCESS! Message ID:', result);
  } catch (err) {
    console.log('FAILED:', err.message);
    if (err.code === 'messaging/registration-token-not-registered') {
      console.log('Token expired. Flutter app la re-login pannu.');
    }
  }
  process.exit(0);
}

test();
