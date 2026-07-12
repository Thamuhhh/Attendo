const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Fee = require('../models/Fee');
const { instFilter, paginatedResponse } = require('../utils/helpers');
const logger = require('../utils/logger');

async function listStudents(req, { page, limit, skip, sort, search }) {
  let filter = instFilter(req);
  if (search) {
    filter = {
      $and: [
        instFilter(req),
        { name: { $regex: search, $options: 'i' } },
      ],
    };
  }

  const [students, total] = await Promise.all([
    Student.find(filter).sort(sort).skip(skip).limit(limit).lean(),
    Student.countDocuments(filter),
  ]);

  return paginatedResponse(students, total, page, limit);
}

async function createStudent(req, { name, phone }) {
  const existing = await Student.findOne(instFilter(req, { name }));
  if (existing) {
    const err = new Error('Student already exists');
    err.statusCode = 400;
    throw err;
  }

  const student = await new Student({
    name,
    phone: phone || '',
    institutionId: req.institution._id,
  }).save();

  logger.info('Student created', { id: student._id, name: student.name, institutionId: req.institution._id });
  return student;
}

async function updateStudent(req, id, updates) {
  const student = await Student.findOneAndUpdate(
    instFilter(req, { _id: id }),
    { $set: updates },
    { new: true }
  );
  if (!student) {
    const err = new Error('Student not found');
    err.statusCode = 404;
    throw err;
  }
  return student;
}

async function removeStudent(req, id) {
  const instId = req.institution._id;
  const delFilter = { studentId: id, institutionId: instId };

  const [, , student] = await Promise.all([
    Attendance.deleteMany(delFilter),
    Fee.deleteMany(delFilter),
    Student.findOneAndDelete(instFilter(req, { _id: id })),
  ]);

  if (!student) {
    const err = new Error('Student not found');
    err.statusCode = 404;
    throw err;
  }

  logger.info('Student removed', { id, institutionId: instId });
  return true;
}

module.exports = { listStudents, createStudent, updateStudent, removeStudent };
