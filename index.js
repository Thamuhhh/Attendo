const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

function todayStr() {
  return new Date().toISOString().split('T')[0];
}

function formatDate(dateStr) {
  const d = new Date(dateStr + 'T00:00:00');
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: '2-digit', year: 'numeric' });
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
  const inst = await db.institutions.findOne({ token });
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
    const existing = await db.institutions.findOne({ email });
    if (existing) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    const token = generateToken();
    const inst = await db.institutions.insert({
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone || '',
      password: hashPassword(password),
      token,
      createdAt: new Date().toISOString()
    });
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
    const inst = await db.institutions.findOne({ email: email.trim().toLowerCase() });
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
    const students = await db.students.find({}).sort({ name: 1 });
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
    const existing = await db.students.findOne({ name: name.trim() });
    if (existing) {
      return res.status(400).json({ error: 'Student already exists' });
    }
    const student = await db.students.insert({ name: name.trim(), phone: phone || '', createdAt: new Date().toISOString() });
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
    const num = await db.students.update({ _id: req.params.id }, { $set: update });
    if (num === 0) return res.status(404).json({ error: 'Student not found' });
    const student = await db.students.findOne({ _id: req.params.id });
    res.json(student);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/students/:id', authMiddleware, async (req, res) => {
  try {
    await db.attendance.remove({ studentId: req.params.id }, { multi: true });
    await db.fees.remove({ studentId: req.params.id }, { multi: true });
    await db.students.remove({ _id: req.params.id });
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

    const records = await db.attendance.find(query).sort({ date: -1 });

    const studentIds = [...new Set(records.map(r => r.studentId))];
    const students = await db.students.find({ _id: { $in: studentIds } });
    const studentMap = {};
    students.forEach(s => { studentMap[s._id] = s.name; });

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

    const existingRecords = await db.attendance.find({ date: attDate });
    const existingMap = {};
    existingRecords.forEach(r => { existingMap[r.studentId] = r; });

    const operations = [];
    for (const rec of records) {
      if (existingMap[rec.studentId]) {
        operations.push(
          db.attendance.update(
            { _id: existingMap[rec.studentId]._id },
            { $set: { status: rec.status } }
          )
        );
      } else {
        operations.push(
          db.attendance.insert({
            studentId: rec.studentId,
            date: attDate,
            status: rec.status
          })
        );
      }
    }

    await Promise.all(operations);
    const updated = await db.attendance.find({ date: attDate });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/attendance/today', authMiddleware, async (req, res) => {
  try {
    const today = todayStr();
    const students = await db.students.find({}).sort({ name: 1 });
    const attendance = await db.attendance.find({ date: today });

    const attMap = {};
    attendance.forEach(a => { attMap[a.studentId] = a.status; });

    const result = students.map(s => ({
      _id: s._id,
      name: s.name,
      phone: s.phone,
      status: attMap[s._id] || 'absent'
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
    const records = await db.fees.find(query).sort({ year: -1, month: -1 });
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
      const existing = await db.fees.findOne({ studentId: rec.studentId, month: rec.month, year: rec.year });
      if (existing) {
        await db.fees.update({ _id: existing._id }, { $set: { status: rec.status, amount: rec.amount || 0, paidDate: rec.status === 'paid' ? new Date().toISOString().split('T')[0] : null } });
        results.push({ ...existing, status: rec.status });
      } else {
        const inserted = await db.fees.insert({
          studentId: rec.studentId,
          month: rec.month,
          year: rec.year,
          status: rec.status || 'unpaid',
          amount: rec.amount || 0,
          paidDate: rec.status === 'paid' ? new Date().toISOString().split('T')[0] : null
        });
        results.push(inserted);
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
    const students = await db.students.find({}).sort({ name: 1 });
    const fees = await db.fees.find({ year: y });

    const summary = students.map(student => {
      const studentFees = fees.filter(f => f.studentId === student._id);
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

    const students = await db.students.find({}).sort({ name: 1 });
    const attendance = await db.attendance.find({ date: { $gte: start, $lte: end } });

    const report = students.map(student => {
      const studentRecords = attendance.filter(a => a.studentId === student._id);
      const present = studentRecords.filter(a => a.status === 'present').length;
      const absent = studentRecords.filter(a => a.status === 'absent').length;
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

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
