const reportService = require('../services/reportService');

exports.monthly = async (req, res, next) => {
  try {
    const y = parseInt(req.query.year) || new Date().getFullYear();
    const m = parseInt(req.query.month) || (new Date().getMonth() + 1);
    const result = await reportService.monthlyReport(req, { year: y, month: m });
    res.json(result);
  } catch (err) {
    next(err);
  }
};
