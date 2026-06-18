const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Holiday = require('../models/Holiday');
const { instFilter, getMonthRange } = require('../utils/helpers');

exports.monthly = async (req, res) => {
  try {
    const y = parseInt(req.query.year) || new Date().getFullYear();
    const m = parseInt(req.query.month) || (new Date().getMonth() + 1);
    const { start, end } = getMonthRange(y, m);

    const students = await Student.find(instFilter(req)).sort({ name: 1 }).lean();
    const attendance = await Attendance.find(
      instFilter(req, { date: { $gte: start, $lte: end } })
    ).lean();
    const holidays = await Holiday.find(
      instFilter(req, { date: { $gte: start, $lte: end } })
    ).lean();
    const holidaySet = new Set(holidays.map(h => h.date));

    const report = students.map(student => {
      const studentRecords = attendance.filter(a => a.studentId === student._id.toString());
      const present = studentRecords.filter(a => a.status === 'present').length;
      const absent = studentRecords.filter(a => a.status === 'absent' && !holidaySet.has(a.date)).length;
      const total = present + absent;
      return {
        _id: student._id, name: student.name, phone: student.phone,
        present, absent, total,
        percentage: total > 0 ? Math.round((present / total) * 100) : 0
      };
    });

    res.json({ year: y, month: m, report });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
