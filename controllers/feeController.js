const feeService = require('../services/feeService');

exports.list = async (req, res, next) => {
  try {
    const result = await feeService.list(req, req.query);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.save = async (req, res, next) => {
  try {
    const result = await feeService.save(req, req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.summary = async (req, res, next) => {
  try {
    const year = parseInt(req.query.year) || new Date().getFullYear();
    const result = await feeService.summary(req, year);
    res.json({ year, summary: result });
  } catch (err) {
    next(err);
  }
};
