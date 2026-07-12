const Holiday = require('../models/Holiday');
const { instFilter } = require('../utils/helpers');
const logger = require('../utils/logger');

async function list(req) {
  const holidays = await Holiday.find(instFilter(req)).sort({ date: 1 }).lean();
  return holidays;
}

async function create(req, { date, name }) {
  const existing = await Holiday.findOne(instFilter(req, { date }));
  if (existing) return existing;

  const holiday = await new Holiday({
    date,
    name: name || 'Holiday',
    institutionId: req.institution._id,
  }).save();

  logger.info('Holiday created', { date, institutionId: req.institution._id });
  return holiday;
}

async function remove(req, date) {
  const result = await Holiday.findOneAndDelete(instFilter(req, { date }));
  if (!result) {
    const err = new Error('Holiday not found');
    err.statusCode = 404;
    throw err;
  }
  logger.info('Holiday removed', { date, institutionId: req.institution._id });
  return true;
}

module.exports = { list, create, remove };
