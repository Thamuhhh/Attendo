const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');

let authToken;
let studentId;
const testEmail = `testatt${Date.now()}@example.com`;

beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/attendo_test_att');
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({ name: 'Att Test', email: testEmail, password: 'test123456' });
  authToken = res.body.accessToken;

  const sRes = await request(app)
    .post('/api/v1/students')
    .set('Authorization', `Bearer ${authToken}`)
    .send({ name: 'Att Student', phone: '1234567890' });
  studentId = sRes.body._id;
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

describe('Attendance Endpoints', () => {
  test('GET /api/v1/attendance/today - should return today data', async () => {
    const res = await request(app)
      .get('/api/v1/attendance/today')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('date');
    expect(res.body).toHaveProperty('records');
  });

  test('POST /api/v1/attendance - save attendance', async () => {
    const res = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        records: [{ studentId, status: 'present' }],
      });
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('POST /api/v1/attendance - invalid status', async () => {
    const res = await request(app)
      .post('/api/v1/attendance')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        records: [{ studentId, status: 'late' }],
      });
    expect(res.statusCode).toBe(400);
  });

  test('GET /api/v1/attendance/weekly - should return 7 days', async () => {
    const res = await request(app)
      .get('/api/v1/attendance/weekly')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveLength(7);
  });

  test('GET /api/v1/attendance/history/:studentId', async () => {
    const res = await request(app)
      .get(`/api/v1/attendance/history/${studentId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });
});
