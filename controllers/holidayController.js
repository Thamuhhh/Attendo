const holidayService = require('../services/holidayService');

exports.list = async (req, res, next) => {
  try {
    const holidays = await holidayService.list(req);
    res.json(holidays.map(h => h.date));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const holiday = await holidayService.create(req, req.body);
    res.json(holiday);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    await holidayService.remove(req, req.params.date);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};
