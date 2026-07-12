const attendanceService = require('../services/attendanceService');

exports.getByDate = async (req, res, next) => {
  try {
    const result = await attendanceService.getByDate(req, req.query);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.save = async (req, res, next) => {
  try {
    const result = await attendanceService.save(req, req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.today = async (req, res, next) => {
  try {
    const result = await attendanceService.today(req);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.history = async (req, res, next) => {
  try {
    const result = await attendanceService.history(req, req.params.studentId, req.query);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.weekly = async (req, res, next) => {
  try {
    const result = await attendanceService.weekly(req);
    res.json(result);
  } catch (err) {
    next(err);
  }
};
