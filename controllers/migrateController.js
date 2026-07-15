const migrateService = require('../services/migrateService');

exports.claim = async (req, res, next) => {
  try {
    const result = await migrateService.claim(req);
    res.json({ message: 'Migration complete', migrated: result });
  } catch (err) {
    next(err);
  }
};
