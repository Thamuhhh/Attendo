const Joi = require('joi');
const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Holiday = require('../models/Holiday');
const { todayStr, instFilter, getMonthRange } = require('../utils/helpers');

const saveSchema = Joi.object({
  date: Joi.string().isoDate(),
  records: Joi.array().items(Joi.object({
    studentId: Joi.string().required(),
    status: Joi.string().valid('present', 'absent').required(),
  })).min(1).required(),
});

exports.getByDate = async (req, res) => {
  try {
    const { date, studentId, year, month } = req.query;
    let extra = {};
    if (date) extra.date = date;
    if (studentId) extra.studentId = studentId;
    if (year && month) {
      const { start, end } = getMonthRange(parseInt(year), parseInt(month));
      extra.date = { $gte: start, $lte: end };
    }

    const hasExtra = Object.keys(extra).length > 0;
    const records = await Attendance.find({
      $or: [
        instFilter(req, extra),
        { $and: [extra, { institutionId: { $exists: false } }] },
      ]
    }).sort({ date: -1 }).lean();
    const studentIds = [...new Set(records.map(r => r.studentId))];
    const students = studentIds.length > 0
      ? await Student.find(instFilter(req, { _id: { $in: studentIds } })).lean()
      : [];
    const studentMap = {};
    students.forEach(s => { studentMap[s._id.toString()] = s.name; });

    res.json(records.map(r => ({ ...r, studentName: studentMap[r.studentId] || 'Unknown' })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.save = async (req, res) => {
  try {
    const { error, value } = saveSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const attDate = value.date || todayStr();
    const instId = req.institution._id.toString();
    const studentIds = value.records.map(r => r.studentId);

    const owned = await Student.countDocuments({
      $or: [
        instFilter(req, { _id: { $in: studentIds } }),
        { _id: { $in: studentIds }, institutionId: { $exists: false } },
      ]
    });
    if (owned !== [...new Set(studentIds)].length) {
      return res.status(403).json({ error: 'Some students do not belong to your institution' });
    }

    const existingRecords = await Attendance.find(instFilter(req, { date: attDate })).lean();
    const existingMap = {};
    existingRecords.forEach(r => { existingMap[r.studentId] = r; });

    const bulkOps = [];
    for (const rec of value.records) {
      if (existingMap[rec.studentId]) {
        bulkOps.push({
          updateOne: {
            filter: { _id: existingMap[rec.studentId]._id },
            update: { $set: { status: rec.status } },
          }
        });
      } else {
        bulkOps.push({
          insertOne: {
            document: { studentId: rec.studentId, institutionId: instId, date: attDate, status: rec.status }
          }
        });
      }
    }

    if (bulkOps.length > 0) await Attendance.bulkWrite(bulkOps);

    const updated = await Attendance.find(instFilter(req, { date: attDate })).lean();
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.today = async (req, res) => {
  try {
    const today = todayStr();
    const instId = req.institution._id.toString();
    const students = await Student.find({
      $or: [
        instFilter(req),
        { institutionId: { $exists: false } },
      ]
    }).sort({ name: 1 }).lean();
    const attendance = await Attendance.find({
      $or: [
        instFilter(req, { date: today }),
        { date: today, institutionId: { $exists: false } },
      ]
    }).lean();

    const attMap = {};
    attendance.forEach(a => { attMap[a.studentId] = a.status; });

    res.json({
      date: today,
      records: students.map(s => ({
        _id: s._id, name: s.name, phone: s.phone,
        status: attMap[s._id.toString()] || 'absent'
      }))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.history = async (req, res) => {
  try {
    const { studentId } = req.params;
    const { year, month } = req.query;
    let extra = { studentId };
    if (year && month) {
      const { start, end } = getMonthRange(parseInt(year), parseInt(month));
      extra.date = { $gte: start, $lte: end };
    }
    const records = await Attendance.find({
      $or: [
        instFilter(req, extra),
        { $and: [extra, { institutionId: { $exists: false } }] },
      ]
    }).sort({ date: -1 }).lean();
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.weekly = async (req, res) => {
  try {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const dayName = d.toLocaleDateString('en-US', { weekday: 'short' });
      const records = await Attendance.find({
        $or: [
          instFilter(req, { date: dateStr }),
          { date: dateStr, institutionId: { $exists: false } },
        ]
      }).lean();
      const present = records.filter(r => r.status === 'present').length;
      const absent = records.filter(r => r.status === 'absent').length;
      days.push({ date: dateStr, day: dayName, present, absent, total: present + absent });
    }
    res.json(days);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
