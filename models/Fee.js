const mongoose = require('mongoose');

const feeSchema = new mongoose.Schema({
  studentId: { type: String, required: true },
  institutionId: { type: String, required: true },
  month: { type: Number, required: true },
  year: { type: Number, required: true },
  status: { type: String, default: 'unpaid', enum: ['paid', 'unpaid'] },
  amount: { type: Number, default: 0 },
  paidDate: { type: String, default: null },
});

feeSchema.index({ institutionId: 1, studentId: 1, month: 1, year: 1 }, { unique: true });

module.exports = mongoose.model('Fee', feeSchema);
