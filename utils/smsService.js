const config = require('../config');
const logger = require('../utils/logger');

let twilioClient = null;

function getTwilioClient() {
  if (!twilioClient && config.sms.twilio.accountSid) {
    const twilio = require('twilio');
    twilioClient = twilio(config.sms.twilio.accountSid, config.sms.twilio.authToken);
  }
  return twilioClient;
}

async function sendSMSviaTwilio(to, message) {
  const client = getTwilioClient();
  if (!client) {
    logger.warn('Twilio not configured, skipping SMS');
    return null;
  }
  try {
    const result = await client.messages.create({
      body: message,
      from: config.sms.twilio.phoneNumber,
      to,
    });
    logger.info('SMS sent via Twilio', { to, sid: result.sid });
    return result;
  } catch (err) {
    logger.error('Twilio SMS failed', { to, error: err.message });
    throw err;
  }
}

async function sendSMSviaMSG91(to, message) {
  if (!config.sms.msg91.apiKey) {
    logger.warn('MSG91 not configured, skipping SMS');
    return null;
  }
  const https = require('https');
  const url = `https://api.msg91.com/api/v5/otp?template_id=${config.sms.msg91.senderId}&mobile=${to}&authkey=${config.sms.msg91.apiKey}&MP=${message}`;
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        logger.info('SMS sent via MSG91', { to });
        resolve(JSON.parse(data));
      });
    }).on('error', (err) => {
      logger.error('MSG91 SMS failed', { to, error: err.message });
      reject(err);
    });
  });
}

async function sendSMS(to, message) {
  if (!to || to.length < 10) {
    logger.warn('Invalid phone number for SMS', { to });
    return null;
  }
  const provider = config.sms.provider;
  if (provider === 'twilio') return sendSMSviaTwilio(to, message);
  if (provider === 'msg91') return sendSMSviaMSG91(to, message);
  logger.warn(`Unknown SMS provider: ${provider}`);
  return null;
}

async function sendAttendanceSMS(to, studentName, date, status) {
  const msg = `Attendo: ${studentName} marked ${status} on ${date}`;
  return sendSMS(to, msg);
}

async function sendFeeReminderSMS(to, studentName, month, year) {
  const msg = `Attendo: Fee pending for ${studentName} for ${month}/${year}`;
  return sendSMS(to, msg);
}

module.exports = { sendSMS, sendAttendanceSMS, sendFeeReminderSMS };
