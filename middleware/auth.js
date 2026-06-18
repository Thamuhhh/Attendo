const Institution = require('../models/Institution');

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const token = header.split(' ')[1];
  const inst = await Institution.findOne({ token }).lean();
  if (!inst) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  req.institution = inst;
  next();
}

module.exports = authMiddleware;
