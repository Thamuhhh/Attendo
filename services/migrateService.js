const Student = require('../models/Student');
const Attendance = require('../models/Attendance');
const Fee = require('../models/Fee');
const Holiday = require('../models/Holiday');
const logger = require('../utils/logger');

async function claim(req) {
  const instId = req.institution._id;
  const filter = {
    $or: [
      { institutionId: { $exists: false } },
      { institutionId: null },
    ],
  };

  const [studentRes, attendanceRes, feeRes, holidayRes] = await Promise.all([
    Student.updateMany(filter, { $set: { institutionId: instId } }),
    Attendance.updateMany(filter, { $set: { institutionId: instId } }),
    Fee.updateMany(filter, { $set: { institutionId: instId } }),
    Holiday.updateMany(filter, { $set: { institutionId: instId } }),
  ]);

  const migrated = {
    students: studentRes.modifiedCount,
    attendance: attendanceRes.modifiedCount,
    fees: feeRes.modifiedCount,
    holidays: holidayRes.modifiedCount,
  };

  logger.info('Migration claim completed', { institutionId: instId, migrated });
  return migrated;
}

module.exports = { claim };
