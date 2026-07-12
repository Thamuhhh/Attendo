const jwt = require('jsonwebtoken');
const Institution = require('../models/Institution');
const config = require('../config');

async function authMiddleware(req, res, next) {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Access denied. No token provided.' });
    }

    const token = header.split(' ')[1];
    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.secret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
      }
      return res.status(401).json({ error: 'Invalid token' });
    }

    const inst = await Institution.findById(decoded.id).select('-password -refreshToken -passwordResetToken').lean();
    if (!inst) {
      return res.status(401).json({ error: 'Institution not found' });
    }

    req.institution = inst;
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = authMiddleware;
