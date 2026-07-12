const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Holiday = require('../models/Holiday');
const { instFilter, getMonthRange } = require('../utils/helpers');

async function monthlyReport(req, { year, month }) {
  const { start, end } = getMonthRange(year, month);

  const [students, attendance, holidays] = await Promise.all([
    Student.find(instFilter(req)).sort({ name: 1 }).lean(),
    Attendance.find(instFilter(req, { date: { $gte: start, $lte: end } })).lean(),
    Holiday.find(instFilter(req, { date: { $gte: start, $lte: end } })).lean(),
  ]);

  const holidaySet = new Set(holidays.map(h => h.date));

  const attendanceByStudent = {};
  attendance.forEach(a => {
    const sid = a.studentId.toString();
    if (!attendanceByStudent[sid]) attendanceByStudent[sid] = [];
    attendanceByStudent[sid].push(a);
  });

  const report = students.map(student => {
    const studentRecords = attendanceByStudent[student._id.toString()] || [];
    const present = studentRecords.filter(a => a.status === 'present').length;
    const absent = studentRecords.filter(a => a.status === 'absent' && !holidaySet.has(a.date)).length;
    const total = present + absent;
    return {
      _id: student._id, name: student.name, phone: student.phone,
      present, absent, total,
      percentage: total > 0 ? Math.round((present / total) * 100) : 0,
    };
  });

  return { year, month, report };
}

module.exports = { monthlyReport };
