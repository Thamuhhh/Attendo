const Joi = require('joi');
const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Fee = require('../models/Fee');
const { instFilter } = require('../utils/helpers');

const createSchema = Joi.object({
  name: Joi.string().trim().min(1).max(100).required(),
  phone: Joi.string().trim().allow('').max(20),
});

const updateSchema = Joi.object({
  name: Joi.string().trim().min(1).max(100),
  phone: Joi.string().trim().allow('').max(20),
}).min(1);

exports.list = async (req, res) => {
  try {
    const students = await Student.find({
      $or: [
        instFilter(req),
        { institutionId: { $exists: false } },
      ]
    }).sort({ name: 1 }).lean();
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.create = async (req, res) => {
  try {
    const { error, value } = createSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const existing = await Student.findOne(instFilter(req, { name: value.name }));
    if (existing) return res.status(400).json({ error: 'Student already exists' });

    const student = await new Student({
      name: value.name, phone: value.phone || '',
      institutionId: req.institution._id.toString(),
    }).save();

    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.update = async (req, res) => {
  try {
    const { error, value } = updateSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const student = await Student.findOneAndUpdate(
      instFilter(req, { _id: req.params.id }),
      { $set: value },
      { new: true }
    );
    if (!student) return res.status(404).json({ error: 'Student not found' });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.remove = async (req, res) => {
  try {
    const instId = req.institution._id.toString();
    const delFilter = { studentId: req.params.id, institutionId: instId };
    await Attendance.deleteMany(delFilter);
    await Fee.deleteMany(delFilter);
    await Student.findOneAndDelete(instFilter(req, { _id: req.params.id }));
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
