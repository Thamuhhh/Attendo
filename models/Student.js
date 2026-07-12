const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  phone: { type: String, default: '' },
  institutionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Institution', required: true, index: true },
  createdAt: { type: Date, default: Date.now },
});

studentSchema.index({ institutionId: 1, name: 1 });
studentSchema.index({ institutionId: 1, createdAt: -1 });

module.exports = mongoose.model('Student', studentSchema);
