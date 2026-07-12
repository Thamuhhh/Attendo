const nodemailer = require('nodemailer');
const config = require('../config');
const logger = require('../utils/logger');

let transporter = null;

function getTransporter() {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: config.smtp.host,
      port: config.smtp.port,
      secure: config.smtp.port === 465,
      auth: {
        user: config.smtp.user,
        pass: config.smtp.pass,
      },
    });
  }
  return transporter;
}

async function sendEmail({ to, subject, html, text }) {
  if (!config.smtp.user) {
    logger.warn('SMTP not configured, skipping email');
    return null;
  }
  try {
    const info = await getTransporter().sendMail({
      from: `"Attendo" <${config.smtp.user}>`,
      to,
      subject,
      html,
      text,
    });
    logger.info('Email sent', { to, messageId: info.messageId });
    return info;
  } catch (err) {
    logger.error('Email send failed', { to, error: err.message });
    throw err;
  }
}

async function sendPasswordResetEmail(to, resetToken) {
  const resetUrl = `${config.cors.origin}/reset-password?token=${resetToken}`;
  return sendEmail({
    to,
    subject: 'Attendo - Password Reset Request',
    html: `
      <h2>Password Reset</h2>
      <p>You requested a password reset for your Attendo account.</p>
      <p>Click the link below to reset your password:</p>
      <a href="${resetUrl}" style="display:inline-block;padding:10px 20px;background:#4CAF50;color:white;text-decoration:none;border-radius:5px;">Reset Password</a>
      <p>This link expires in 1 hour.</p>
      <p>If you didn't request this, please ignore this email.</p>
    `,
  });
}

async function sendAttendanceAlert(to, studentName, date, status) {
  return sendEmail({
    to,
    subject: `Attendo - ${studentName} marked ${status} on ${date}`,
    html: `
      <h2>Attendance Update</h2>
      <p><strong>${studentName}</strong> has been marked as <strong>${status}</strong> on <strong>${date}</strong>.</p>
    `,
  });
}

async function sendFeeReminder(to, studentName, month, year) {
  return sendEmail({
    to,
    subject: `Attendo - Fee Reminder for ${studentName}`,
    html: `
      <h2>Fee Reminder</h2>
      <p>This is a reminder that the fee for <strong>${studentName}</strong> for <strong>${month}/${year}</strong> is pending.</p>
    `,
  });
}

module.exports = { sendEmail, sendPasswordResetEmail, sendAttendanceAlert, sendFeeReminder };
