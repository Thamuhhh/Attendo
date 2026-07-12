const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  institutionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Institution', required: true },
  date: { type: String, required: true },
  status: { type: String, required: true, enum: ['present', 'absent'] },
});

attendanceSchema.index({ institutionId: 1, studentId: 1, date: 1 }, { unique: true });
attendanceSchema.index({ institutionId: 1, date: 1 });
attendanceSchema.index({ studentId: 1, date: -1 });
attendanceSchema.index({ institutionId: 1, studentId: 1, date: -1 });

module.exports = mongoose.model('Attendance', attendanceSchema);
