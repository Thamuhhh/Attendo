const Student = require('../models/Student');
const Fee = require('../models/Fee');
const Institution = require('../models/Institution');
const { todayStr, instFilter } = require('../utils/helpers');
const { sendFeeNotification } = require('../utils/pushService');
const { sendFeeReminderSMS } = require('../utils/smsService');
const { sendFeeReminder } = require('../utils/emailService');
const logger = require('../utils/logger');

async function list(req, { studentId, year, month }) {
  const extra = {};
  if (studentId) extra.studentId = studentId;
  if (year) extra.year = parseInt(year);
  if (month) extra.month = parseInt(month);
  return Fee.find(instFilter(req, extra)).sort({ year: -1, month: -1 }).lean();
}

async function save(req, { records }) {
  const instId = req.institution._id;
  const studentIds = [...new Set(records.map(r => r.studentId))];

  const owned = await Student.countDocuments(instFilter(req, { _id: { $in: studentIds } }));
  if (owned !== studentIds.length) {
    const err = new Error('Some students do not belong to your institution');
    err.statusCode = 403;
    throw err;
  }

  const bulkOps = [];
  const results = [];

  for (const rec of records) {
    if (!rec.studentId || !rec.month || !rec.year) {
      const err = new Error('Each record needs studentId, month & year');
      err.statusCode = 400;
      throw err;
    }

    const filter = instFilter(req, { studentId: rec.studentId, month: rec.month, year: rec.year });
    const existing = await Fee.findOne(filter);

    if (existing) {
      bulkOps.push({
        updateOne: {
          filter: { _id: existing._id },
          update: {
            $set: {
              status: rec.status || 'unpaid',
              amount: rec.amount || 0,
              paidDate: rec.status === 'paid' ? todayStr() : null,
            },
          },
        },
      });
      results.push({
        ...existing.toObject(),
        status: rec.status || 'unpaid',
        paidDate: rec.status === 'paid' ? todayStr() : null,
      });
    } else {
      bulkOps.push({
        insertOne: {
          document: {
            studentId: rec.studentId,
            institutionId: instId,
            month: rec.month,
            year: rec.year,
            status: rec.status || 'unpaid',
            amount: rec.amount || 0,
            paidDate: rec.status === 'paid' ? todayStr() : null,
          },
        },
      });
      results.push({
        studentId: rec.studentId,
        institutionId: instId,
        month: rec.month,
        year: rec.year,
        status: rec.status || 'unpaid',
        amount: rec.amount || 0,
        paidDate: rec.status === 'paid' ? todayStr() : null,
      });
    }
  }

  if (bulkOps.length > 0) await Fee.bulkWrite(bulkOps);

  const institution = await Institution.findById(instId).lean().catch(() => null);
  const uniqueStudentIds = [...new Set(records.map(r => r.studentId))];
  const students = await Student.find(instFilter(req, { _id: { $in: uniqueStudentIds } })).lean();
  const studentMap = {};
  students.forEach(s => { studentMap[s._id.toString()] = s.name; });

  for (const rec of records) {
    if (rec.status === 'unpaid') {
      const studentName = studentMap[rec.studentId] || 'Unknown';
      try {
        if (institution) {
          sendFeeNotification(institution, studentName, rec.month, rec.year).catch(() => {});
        }
        if (institution && institution.email) {
          sendFeeReminder(institution.email, studentName, rec.month, rec.year).catch(() => {});
        }
        if (institution && institution.phone) {
          sendFeeReminderSMS(institution.phone, studentName, rec.month, rec.year).catch(() => {});
        }
      } catch (_e) {
        logger.warn('Fee notification failed', { studentId: rec.studentId });
      }
    }
  }

  logger.info('Fees saved', { count: records.length, institutionId: instId });
  return results;
}

async function summary(req, year) {
  const students = await Student.find(instFilter(req)).sort({ name: 1 }).lean();
  const fees = await Fee.find(instFilter(req, { year })).lean();

  const feeMap = {};
  fees.forEach(f => {
    const sid = f.studentId.toString();
    if (!feeMap[sid]) feeMap[sid] = [];
    feeMap[sid].push(f);
  });

  return students.map(student => {
    const studentFees = feeMap[student._id.toString()] || [];
    const paidMonths = studentFees.filter(f => f.status === 'paid').length;
    return {
      _id: student._id, name: student.name, phone: student.phone,
      paidMonths, totalMonths: studentFees.length,
      dueMonths: studentFees.length - paidMonths,
      records: studentFees.map(f => ({ month: f.month, status: f.status, amount: f.amount })),
    };
  });
}

module.exports = { list, save, summary };
