const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const Institution = require('../models/Institution');
const config = require('../config');
const logger = require('../utils/logger');
const { sendPasswordResetEmail } = require('../utils/emailService');

const SALT_ROUNDS = 10;

function generateAccessToken(institution) {
  return jwt.sign(
    { id: institution._id, email: institution.email },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
}

function generateRefreshToken(institution) {
  return jwt.sign(
    { id: institution._id, type: 'refresh' },
    config.jwt.refreshSecret,
    { expiresIn: config.jwt.refreshExpiresIn }
  );
}

function legacyHash(pw) {
  return crypto.createHash('sha256').update(pw).digest('hex');
}

async function register({ name, email, phone, password }) {
  const existing = await Institution.findOne({ email: email.toLowerCase() });
  if (existing) {
    const err = new Error('Email already registered');
    err.statusCode = 400;
    throw err;
  }

  const hashed = await bcrypt.hash(password, SALT_ROUNDS);
  const inst = await new Institution({
    name,
    email: email.toLowerCase(),
    phone: phone || '',
    password: hashed,
  }).save();

  const accessToken = generateAccessToken(inst);
  const refreshToken = generateRefreshToken(inst);
  inst.refreshToken = refreshToken;
  await inst.save();

  logger.info('Institution registered', { id: inst._id, email: inst.email });

  return {
    accessToken,
    refreshToken,
    institution: { id: String(inst._id || ''), name: String(inst.name || ''), email: String(inst.email || '') },
  };
}

async function login({ email, password }) {
  const inst = await Institution.findOne({ email: email.toLowerCase() });
  if (!inst) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  const match = await bcrypt.compare(password, inst.password);
  if (!match) {
    const legacyMatch = inst.password === legacyHash(password);
    if (!legacyMatch) {
      const err = new Error('Invalid email or password');
      err.statusCode = 401;
      throw err;
    }
    inst.password = await bcrypt.hash(password, SALT_ROUNDS);
  }

  const accessToken = generateAccessToken(inst);
  const refreshToken = generateRefreshToken(inst);
  inst.refreshToken = refreshToken;
  await inst.save();

  logger.info('Institution logged in', { id: inst._id, email: inst.email });

  return {
    accessToken,
    refreshToken,
    institution: { id: String(inst._id || ''), name: String(inst.name || ''), email: String(inst.email || '') },
  };
}

async function refreshAccessToken(token) {
  let decoded;
  try {
    decoded = jwt.verify(token, config.jwt.refreshSecret);
  } catch (_err) {
    const error = new Error('Invalid refresh token');
    error.statusCode = 401;
    throw error;
  }

  const inst = await Institution.findById(decoded.id);
  if (!inst || inst.refreshToken !== token) {
    const err = new Error('Invalid refresh token');
    err.statusCode = 401;
    throw err;
  }

  const accessToken = generateAccessToken(inst);
  const newRefreshToken = generateRefreshToken(inst);
  inst.refreshToken = newRefreshToken;
  await inst.save();

  return { accessToken, refreshToken: newRefreshToken };
}

async function logout(refreshToken) {
  if (!refreshToken) return;
  const decoded = jwt.verify(refreshToken, config.jwt.refreshSecret, { ignoreExpiration: true });
  await Institution.findByIdAndUpdate(decoded.id, { refreshToken: null });
}

async function forgotPassword(email) {
  const inst = await Institution.findOne({ email: email.toLowerCase() });
  if (!inst) {
    logger.warn('Password reset requested for non-existent email', { email });
    return;
  }

  const resetToken = crypto.randomBytes(32).toString('hex');
  const hashedToken = crypto.createHash('sha256').update(resetToken).digest('hex');

  inst.passwordResetToken = hashedToken;
  inst.passwordResetExpires = new Date(Date.now() + 60 * 60 * 1000);
  await inst.save();

  try {
    await sendPasswordResetEmail(inst.email, resetToken);
  } catch (emailErr) {
    logger.error('Failed to send reset email', { error: emailErr.message });
  }

  return true;
}

async function resetPassword(token, newPassword) {
  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

  const inst = await Institution.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: new Date() },
  });

  if (!inst) {
    const err = new Error('Invalid or expired reset token');
    err.statusCode = 400;
    throw err;
  }

  inst.password = await bcrypt.hash(newPassword, SALT_ROUNDS);
  inst.passwordResetToken = null;
  inst.passwordResetExpires = null;
  inst.refreshToken = null;
  await inst.save();

  logger.info('Password reset completed', { id: inst._id });
  return true;
}

async function getProfile(instId) {
  const inst = await Institution.findById(instId).select('-password -refreshToken -passwordResetToken -passwordResetExpires').lean();
  if (!inst) {
    const err = new Error('Institution not found');
    err.statusCode = 404;
    throw err;
  }
  return {
    _id: String(inst._id || ''),
    name: String(inst.name || ''),
    email: String(inst.email || ''),
    phone: String(inst.phone || ''),
    createdAt: inst.createdAt,
  };
}

async function updateFcmToken(instId, fcmToken) {
  await Institution.findByIdAndUpdate(instId, { fcmToken });
  return true;
}

module.exports = {
  register,
  login,
  refreshAccessToken,
  logout,
  forgotPassword,
  resetPassword,
  getProfile,
  updateFcmToken,
};
