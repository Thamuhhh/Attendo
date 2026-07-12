const studentService = require('../services/studentService');

exports.list = async (req, res, next) => {
  try {
    const pagination = {
      page: parseInt(req.query.page, 10) || 1,
      limit: Math.min(100, parseInt(req.query.limit, 10) || 20),
      sort: { name: 1 },
      skip: ((parseInt(req.query.page, 10) || 1) - 1) * (Math.min(100, parseInt(req.query.limit, 10) || 20)),
      search: req.query.search || '',
    };
    const result = await studentService.listStudents(req, pagination);
    res.json(result);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const student = await studentService.createStudent(req, req.body);
    res.status(201).json(student);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const student = await studentService.updateStudent(req, req.params.id, req.body);
    res.json(student);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    await studentService.removeStudent(req, req.params.id);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};
