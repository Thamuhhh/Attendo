const mongoose = require('mongoose');

const holidaySchema = new mongoose.Schema({
  date: { type: String, required: true, unique: true },
  name: { type: String, default: 'Holiday' },
});

module.exports = mongoose.model('Holiday', holidaySchema);
