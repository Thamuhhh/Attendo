const Holiday = require('../models/Holiday');
const { instFilter } = require('../utils/helpers');

exports.list = async (req, res) => {
  try {
    const holidays = await Holiday.find(instFilter(req)).sort({ date: 1 }).lean();
    res.json(holidays.map(h => h.date));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.create = async (req, res) => {
  try {
    const { date, name } = req.body;
    if (!date) return res.status(400).json({ error: 'Date required' });
    const existing = await Holiday.findOne(instFilter(req, { date }));
    if (existing) return res.json(existing);
    const holiday = await new Holiday({
      date, name: name || 'Holiday', institutionId: req.institution._id.toString()
    }).save();
    res.json(holiday);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.remove = async (req, res) => {
  try {
    await Holiday.findOneAndDelete(instFilter(req, { date: req.params.date }));
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
