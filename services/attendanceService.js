const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Institution = require('../models/Institution');
const { todayStr, instFilter, getMonthRange } = require('../utils/helpers');
const { sendAttendanceNotification } = require('../utils/pushService');
const { sendAttendanceSMS } = require('../utils/smsService');
const { sendAttendanceAlert } = require('../utils/emailService');
const logger = require('../utils/logger');

async function getByDate(req, { date, studentId, year, month }) {
  const extra = {};
  if (date) extra.date = date.slice(0, 10);
  if (studentId) extra.studentId = studentId;
  if (year && month) {
    const { start, end } = getMonthRange(parseInt(year), parseInt(month));
    extra.date = { $gte: start, $lte: end };
  }

  const records = await Attendance.find(instFilter(req, extra)).sort({ date: -1 }).lean();

  const studentIds = [...new Set(records.map(r => r.studentId))];
  const students = studentIds.length > 0
    ? await Student.find(instFilter(req, { _id: { $in: studentIds } })).lean()
    : [];
  const studentMap = {};
  students.forEach(s => { studentMap[s._id.toString()] = s.name; });

  return records.map(r => ({ ...r, studentName: studentMap[r.studentId] || 'Unknown' }));
}

async function save(req, { date, records }) {
  const attDate = (date || todayStr()).slice(0, 10);
  const instId = req.institution._id;
  const studentIds = [...new Set(records.map(r => r.studentId))];

  const owned = await Student.countDocuments(instFilter(req, { _id: { $in: studentIds } }));
  if (owned !== studentIds.length) {
    const err = new Error('Some students do not belong to your institution');
    err.statusCode = 403;
    throw err;
  }

  const existingRecords = await Attendance.find(instFilter(req, { date: attDate })).lean();
  const existingMap = {};
  existingRecords.forEach(r => { existingMap[r.studentId.toString()] = r; });

  const bulkOps = [];
  for (const rec of records) {
    if (existingMap[rec.studentId]) {
      bulkOps.push({
        updateOne: {
          filter: { _id: existingMap[rec.studentId]._id },
          update: { $set: { status: rec.status } },
        },
      });
    } else {
      bulkOps.push({
        insertOne: {
          document: { studentId: rec.studentId, institutionId: instId, date: attDate, status: rec.status },
        },
      });
    }
  }

  if (bulkOps.length > 0) await Attendance.bulkWrite(bulkOps);

  const updated = await Attendance.find(instFilter(req, { date: attDate })).lean();

  const changedStudentIds = records.map(r => r.studentId);
  const students = await Student.find(instFilter(req, { _id: { $in: changedStudentIds } })).lean();
  const studentMap = {};
  students.forEach(s => { studentMap[s._id.toString()] = s.name; });

  const institution = await Institution.findById(instId).lean().catch(() => null);

  for (const rec of records) {
    const studentName = studentMap[rec.studentId] || 'Unknown';
    try {
      if (institution) {
        sendAttendanceNotification(institution, studentName, attDate, rec.status).catch(() => {});
      }
      if (institution && institution.email) {
        sendAttendanceAlert(institution.email, studentName, attDate, rec.status).catch(() => {});
      }
      if (institution && institution.phone) {
        sendAttendanceSMS(institution.phone, studentName, attDate, rec.status).catch(() => {});
      }
    } catch (_e) {
      logger.warn('Notification failed for student', { studentId: rec.studentId });
    }
  }

  return updated;
}

async function today(req) {
  const todayDate = todayStr();
  const students = await Student.find(instFilter(req)).sort({ name: 1 }).lean();
  const attendance = await Attendance.find(instFilter(req, { date: todayDate })).lean();

  const attMap = {};
  attendance.forEach(a => { attMap[a.studentId.toString()] = a.status; });

  return {
    date: todayDate,
    records: students.map(s => ({
      _id: s._id, name: s.name, phone: s.phone,
      status: attMap[s._id.toString()] || 'absent',
    })),
  };
}

async function history(req, studentId, { year, month }) {
  const extra = { studentId };
  if (year && month) {
    const { start, end } = getMonthRange(parseInt(year), parseInt(month));
    extra.date = { $gte: start, $lte: end };
  }
  return Attendance.find(instFilter(req, extra)).sort({ date: -1 }).lean();
}

async function weekly(req) {
  const instId = req.institution._id;
  const dates = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    dates.push(d.toISOString().split('T')[0]);
  }

  const records = await Attendance.find({
    institutionId: instId,
    date: { $in: dates },
  }).lean();

  const dayMap = {};
  dates.forEach(date => {
    dayMap[date] = { date, present: 0, absent: 0, total: 0 };
  });

  records.forEach(r => {
    if (dayMap[r.date]) {
      dayMap[r.date][r.status]++;
      dayMap[r.date].total++;
    }
  });

  return dates.map(date => {
    const d = new Date(date + 'T00:00:00');
    return {
      ...dayMap[date],
      day: d.toLocaleDateString('en-US', { weekday: 'short' }),
    };
  });
}

module.exports = { getByDate, save, today, history, weekly };
