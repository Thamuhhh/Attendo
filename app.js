const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

require('./db');

const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/students');
const attendanceRoutes = require('./routes/attendance');
const feeRoutes = require('./routes/fees');
const holidayRoutes = require('./routes/holidays');
const reportRoutes = require('./routes/reports');
const authMiddleware = require('./middleware/auth');
const { instFilter } = require('./utils/helpers');
const Student = require('./models/Student');
const Attendance = require('./models/Attendance');
const Fee = require('./models/Fee');
const Holiday = require('./models/Holiday');

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
});
app.use('/api/', limiter);

app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/fees', feeRoutes);
app.use('/api/holidays', holidayRoutes);
app.use('/api/report', reportRoutes);

app.post('/api/migrate/claim', authMiddleware, async (req, res) => {
  try {
    const instId = req.institution._id.toString();
    const migrated = {};
    migrated.students = (await Student.updateMany(
      { institutionId: { $exists: false } },
      { $set: { institutionId: instId } }
    )).modifiedCount;
    migrated.attendance = (await Attendance.updateMany(
      { institutionId: { $exists: false } },
      { $set: { institutionId: instId } }
    )).modifiedCount;
    migrated.fees = (await Fee.updateMany(
      { institutionId: { $exists: false } },
      { $set: { institutionId: instId } }
    )).modifiedCount;
    migrated.holidays = (await Holiday.updateMany(
      { institutionId: { $exists: false } },
      { $set: { institutionId: instId } }
    )).modifiedCount;
    res.json({ message: 'Migration complete', migrated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api', (req, res) => {
  res.json({ message: 'Attendo API is running' });
});

module.exports = app;
