const mongoose = require('mongoose');

const feeSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  institutionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Institution', required: true },
  month: { type: Number, required: true, min: 1, max: 12 },
  year: { type: Number, required: true },
  status: { type: String, default: 'unpaid', enum: ['paid', 'unpaid'] },
  amount: { type: Number, default: 0 },
  paidDate: { type: String, default: null },
});

feeSchema.index({ institutionId: 1, studentId: 1, month: 1, year: 1 }, { unique: true });
feeSchema.index({ institutionId: 1, year: 1, status: 1 });

module.exports = mongoose.model('Fee', feeSchema);
