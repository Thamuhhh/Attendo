const mongoose = require('mongoose');

const holidaySchema = new mongoose.Schema({
  institutionId: { type: String, required: true },
  date: { type: String, required: true },
  name: { type: String, default: 'Holiday' },
});

holidaySchema.index({ institutionId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Holiday', holidaySchema);
