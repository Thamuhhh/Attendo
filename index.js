const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
require('./db');
const Institution = require('./models/Institution');
const Student = require('./models/Student');
const Attendance = require('./models/Attendance');
const Fee = require('./models/Fee');
const Holiday = require('./models/Holiday');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

function todayStr() {
  return new Date().toISOString().split('T')[0];
}

function getMonthRange(year, month) {
  const start = `${year}-${String(month).padStart(2, '0')}-01`;
  const endDate = new Date(year, month, 0);
  const end = `${year}-${String(month).padStart(2, '0')}-${String(endDate.getDate()).padStart(2, '0')}`;
  return { start, end };
}

function hashPassword(pw) {
  return crypto.createHash('sha256').update(pw).digest('hex');
}

function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const token = header.split(' ')[1];
  const inst = await Institution.findOne({ token }).lean();
  if (!inst) {
    return res.status(401).json({ error: 'Invalid token' });
  }
  req.institution = inst;
  next();
}

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email & password required' });
    }
    const existing = await Institution.findOne({ email: email.trim().toLowerCase() });
    if (existing) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    const token = generateToken();
    const inst = await new Institution({
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone || '',
      password: hashPassword(password),
      token,
    }).save();
    res.json({ token, institution: { id: inst._id, name: inst.name, email: inst.email } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email & password required' });
    }
    const inst = await Institution.findOne({ email: email.trim().toLowerCase() });
    if (!inst || inst.password !== hashPassword(password)) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    res.json({ token: inst.token, institution: { id: inst._id, name: inst.name, email: inst.email } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/auth/me', authMiddleware, async (req, res) => {
  res.json({ institution: { id: req.institution._id, name: req.institution.name, email: req.institution.email } });
});

app.get('/api/students', authMiddleware, async (req, res) => {
  try {
    const students = await Student.find({}).sort({ name: 1 }).lean();
    res.json(students);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/students', authMiddleware, async (req, res) => {
  try {
    const { name, phone } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Name is required' });
    }
    const existing = await Student.findOne({ name: name.trim() });
    if (existing) {
      return res.status(400).json({ error: 'Student already exists' });
    }
    const student = await new Student({ name: name.trim(), phone: phone || '' }).save();
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/students/:id', authMiddleware, async (req, res) => {
  try {
    const { name, phone } = req.body;
    const update = {};
    if (name) update.name = name.trim();
    if (phone !== undefined) update.phone = phone;
    const student = await Student.findByIdAndUpdate(req.params.id, { $set: update }, { new: true });
    if (!student) return res.status(404).json({ error: 'Student not found' });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/students/:id', authMiddleware, async (req, res) => {
  try {
    await Attendance.deleteMany({ studentId: req.params.id });
    await Fee.deleteMany({ studentId: req.params.id });
    await Student.findByIdAndDelete(req.params.id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/attendance', authMiddleware, async (req, res) => {
  try {
    const { date, studentId, year, month } = req.query;

    let query = {};
    if (date) query.date = date;
    if (studentId) query.studentId = studentId;
    if (year && month) {
      const { start, end } = getMonthRange(parseInt(year), parseInt(month));
      query.date = { $gte: start, $lte: end };
    }

    const records = await Attendance.find(query).sort({ date: -1 }).lean();

    const studentIds = [...new Set(records.map(r => r.studentId))];
    const students = studentIds.length > 0 ? await Student.find({ _id: { $in: studentIds } }).lean() : [];
    const studentMap = {};
    students.forEach(s => { studentMap[s._id.toString()] = s.name; });

    const result = records.map(r => ({
      ...r,
      studentName: studentMap[r.studentId] || 'Unknown'
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/attendance', authMiddleware, async (req, res) => {
  try {
    const { date, records } = req.body;
    const attDate = date || todayStr();

    const existingRecords = await Attendance.find({ date: attDate }).lean();
    const existingMap = {};
    existingRecords.forEach(r => { existingMap[r.studentId] = r; });

    const bulkOps = [];
    for (const rec of records) {
      if (existingMap[rec.studentId]) {
        bulkOps.push({
          updateOne: {
            filter: { _id: existingMap[rec.studentId]._id },
            update: { $set: { status: rec.status } },
          }
        });
      } else {
        bulkOps.push({
          insertOne: {
            document: { studentId: rec.studentId, date: attDate, status: rec.status }
          }
        });
      }
    }

    if (bulkOps.length > 0) {
      await Attendance.bulkWrite(bulkOps);
    }

    const updated = await Attendance.find({ date: attDate }).lean();
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/attendance/today', authMiddleware, async (req, res) => {
  try {
    const today = todayStr();
    const students = await Student.find({}).sort({ name: 1 }).lean();
    const attendance = await Attendance.find({ date: today }).lean();

    const attMap = {};
    attendance.forEach(a => { attMap[a.studentId] = a.status; });

    const result = students.map(s => ({
      _id: s._id,
      name: s.name,
      phone: s.phone,
      status: attMap[s._id.toString()] || 'absent'
    }));

    res.json({ date: today, records: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/fees', authMiddleware, async (req, res) => {
  try {
    const { studentId, year, month } = req.query;
    let query = {};
    if (studentId) query.studentId = studentId;
    if (year) query.year = parseInt(year);
    if (month) query.month = parseInt(month);
    const records = await Fee.find(query).sort({ year: -1, month: -1 }).lean();
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/fees', authMiddleware, async (req, res) => {
  try {
    const { records } = req.body;
    const results = [];
    for (const rec of records) {
      const existing = await Fee.findOne({ studentId: rec.studentId, month: rec.month, year: rec.year });
      if (existing) {
        await Fee.findByIdAndUpdate(existing._id, {
          $set: {
            status: rec.status,
            amount: rec.amount || 0,
            paidDate: rec.status === 'paid' ? todayStr() : null
          }
        });
        results.push({ ...existing.toObject(), status: rec.status, paidDate: rec.status === 'paid' ? todayStr() : null });
      } else {
        const inserted = await new Fee({
          studentId: rec.studentId,
          month: rec.month,
          year: rec.year,
          status: rec.status || 'unpaid',
          amount: rec.amount || 0,
          paidDate: rec.status === 'paid' ? todayStr() : null
        }).save();
        results.push(inserted.toObject());
      }
    }
    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/fees/summary', authMiddleware, async (req, res) => {
  try {
    const { year } = req.query;
    const y = parseInt(year) || new Date().getFullYear();
    const students = await Student.find({}).sort({ name: 1 }).lean();
    const fees = await Fee.find({ year: y }).lean();

    const summary = students.map(student => {
      const studentFees = fees.filter(f => f.studentId === student._id.toString());
      const paidMonths = studentFees.filter(f => f.status === 'paid').length;
      const totalMonths = studentFees.length;
      return {
        _id: student._id,
        name: student.name,
        phone: student.phone,
        paidMonths,
        totalMonths,
        dueMonths: totalMonths - paidMonths,
        records: studentFees.map(f => ({ month: f.month, status: f.status, amount: f.amount }))
      };
    });

    res.json({ year: y, summary });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/report/monthly', authMiddleware, async (req, res) => {
  try {
    const { year, month } = req.query;
    const y = parseInt(year) || new Date().getFullYear();
    const m = parseInt(month) || (new Date().getMonth() + 1);
    const { start, end } = getMonthRange(y, m);

    const students = await Student.find({}).sort({ name: 1 }).lean();
    const attendance = await Attendance.find({ date: { $gte: start, $lte: end } }).lean();
    const holidays = await Holiday.find({ date: { $gte: start, $lte: end } }).lean();
    const holidaySet = new Set(holidays.map(h => h.date));

    const report = students.map(student => {
      const studentRecords = attendance.filter(a => a.studentId === student._id.toString());
      const present = studentRecords.filter(a => a.status === 'present').length;
      const absent = studentRecords.filter(a => a.status === 'absent' && !holidaySet.has(a.date)).length;
      const total = present + absent;
      return {
        _id: student._id,
        name: student.name,
        phone: student.phone,
        present,
        absent,
        total,
        percentage: total > 0 ? Math.round((present / total) * 100) : 0
      };
    });

    res.json({ year: y, month: m, report });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/holidays', authMiddleware, async (req, res) => {
  try {
    const holidays = await Holiday.find({}).sort({ date: 1 }).lean();
    res.json(holidays.map(h => h.date));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/holidays', authMiddleware, async (req, res) => {
  try {
    const { date, name } = req.body;
    if (!date) return res.status(400).json({ error: 'Date required' });
    const existing = await Holiday.findOne({ date });
    if (existing) return res.json(existing);
    const holiday = await new Holiday({ date, name: name || 'Holiday' }).save();
    res.json(holiday);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/holidays/:date', authMiddleware, async (req, res) => {
  try {
    await Holiday.findOneAndDelete({ date: req.params.date });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/attendance/history/:studentId', authMiddleware, async (req, res) => {
  try {
    const { studentId } = req.params;
    const { year, month } = req.query;
    let query = { studentId };
    if (year && month) {
      const { start, end } = getMonthRange(parseInt(year), parseInt(month));
      query.date = { $gte: start, $lte: end };
    }
    const records = await Attendance.find(query).sort({ date: -1 }).lean();
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/attendance/weekly', authMiddleware, async (req, res) => {
  try {
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const dayName = d.toLocaleDateString('en-US', { weekday: 'short' });
      const records = await Attendance.find({ date: dateStr }).lean();
      const present = records.filter(r => r.status === 'present').length;
      const absent = records.filter(r => r.status === 'absent').length;
      days.push({ date: dateStr, day: dayName, present, absent, total: present + absent });
    }
    res.json(days);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
