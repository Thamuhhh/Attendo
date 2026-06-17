const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  studentId: { type: String, required: true },
  institutionId: { type: String, required: true },
  date: { type: String, required: true },
  status: { type: String, required: true, enum: ['present', 'absent'] },
});

attendanceSchema.index({ institutionId: 1, studentId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
