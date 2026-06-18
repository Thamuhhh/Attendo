const Student = require('../models/Student');
const Fee = require('../models/Fee');
const { todayStr, instFilter } = require('../utils/helpers');

exports.list = async (req, res) => {
  try {
    const { studentId, year, month } = req.query;
    let extra = {};
    if (studentId) extra.studentId = studentId;
    if (year) extra.year = parseInt(year);
    if (month) extra.month = parseInt(month);
    const records = await Fee.find(instFilter(req, extra)).sort({ year: -1, month: -1 }).lean();
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.save = async (req, res) => {
  try {
    const { records } = req.body;
    if (!records || !Array.isArray(records) || records.length === 0) {
      return res.status(400).json({ error: 'Records array required' });
    }

    const instId = req.institution._id.toString();
    const studentIds = records.map(r => r.studentId);
    const owned = await Student.countDocuments(instFilter(req, { _id: { $in: studentIds } }));
    if (owned !== [...new Set(studentIds)].length) {
      return res.status(403).json({ error: 'Some students do not belong to your institution' });
    }

    const results = [];
    for (const rec of records) {
      if (!rec.studentId || !rec.month || !rec.year) {
        return res.status(400).json({ error: 'Each record needs studentId, month & year' });
      }
      const existing = await Fee.findOne(
        instFilter(req, { studentId: rec.studentId, month: rec.month, year: rec.year })
      );
      if (existing) {
        await Fee.findByIdAndUpdate(existing._id, {
          $set: {
            status: rec.status || 'unpaid',
            amount: rec.amount || 0,
            paidDate: rec.status === 'paid' ? todayStr() : null
          }
        });
        results.push({ ...existing.toObject(), status: rec.status || 'unpaid', paidDate: rec.status === 'paid' ? todayStr() : null });
      } else {
        const inserted = await new Fee({
          studentId: rec.studentId, institutionId: instId,
          month: rec.month, year: rec.year,
          status: rec.status || 'unpaid', amount: rec.amount || 0,
          paidDate: rec.status === 'paid' ? todayStr() : null
        }).save();
        results.push(inserted.toObject());
      }
    }
    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.summary = async (req, res) => {
  try {
    const y = parseInt(req.query.year) || new Date().getFullYear();
    const students = await Student.find(instFilter(req)).sort({ name: 1 }).lean();
    const fees = await Fee.find(instFilter(req, { year: y })).lean();

    const summary = students.map(student => {
      const studentFees = fees.filter(f => f.studentId === student._id.toString());
      const paidMonths = studentFees.filter(f => f.status === 'paid').length;
      return {
        _id: student._id, name: student.name, phone: student.phone,
        paidMonths, totalMonths: studentFees.length,
        dueMonths: studentFees.length - paidMonths,
        records: studentFees.map(f => ({ month: f.month, status: f.status, amount: f.amount }))
      };
    });

    res.json({ year: y, summary });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
