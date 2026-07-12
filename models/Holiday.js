const mongoose = require('mongoose');

const holidaySchema = new mongoose.Schema({
  institutionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Institution', required: true },
  date: { type: String, required: true },
  name: { type: String, default: 'Holiday' },
});

holidaySchema.index({ institutionId: 1, date: 1 }, { unique: true });
holidaySchema.index({ institutionId: 1 });

module.exports = mongoose.model('Holiday', holidaySchema);
