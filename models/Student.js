const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  phone: { type: String, default: '' },
  institutionId: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

studentSchema.index({ institutionId: 1, name: 1 });

module.exports = mongoose.model('Student', studentSchema);
