const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../app');

let authToken;
let refreshToken;
const testEmail = `test${Date.now()}@example.com`;

beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/attendo_test');
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.disconnect();
});

describe('Auth Endpoints', () => {
  test('POST /api/v1/auth/register - should register', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Test Institution',
        email: testEmail,
        password: 'test123456',
      });
    expect(res.statusCode).toBe(201);
    expect(res.body).toHaveProperty('accessToken');
    expect(res.body).toHaveProperty('refreshToken');
    expect(res.body.institution).toHaveProperty('id');
    authToken = res.body.accessToken;
    refreshToken = res.body.refreshToken;
  });

  test('POST /api/v1/auth/register - duplicate email', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'Test Institution 2',
        email: testEmail,
        password: 'test123456',
      });
    expect(res.statusCode).toBe(400);
  });

  test('POST /api/v1/auth/login - should login', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: testEmail, password: 'test123456' });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('accessToken');
  });

  test('POST /api/v1/auth/login - wrong password', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: testEmail, password: 'wrongpassword' });
    expect(res.statusCode).toBe(401);
  });

  test('POST /api/v1/auth/refresh - should refresh token', async () => {
    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('accessToken');
  });

  test('GET /api/v1/auth/me - should return profile', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.institution).toHaveProperty('name');
  });

  test('GET /api/v1/auth/me - no token', async () => {
    const res = await request(app).get('/api/v1/auth/me');
    expect(res.statusCode).toBe(401);
  });

  test('POST /api/v1/auth/logout - should logout', async () => {
    const res = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ refreshToken });
    expect(res.statusCode).toBe(200);
  });
});

describe('Health Check', () => {
  test('GET /api/health', async () => {
    const res = await request(app).get('/api/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('Students Endpoints', () => {
  let studentId;

  test('POST /api/v1/students - create student', async () => {
    const res = await request(app)
      .post('/api/v1/students')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Test Student', phone: '1234567890' });
    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe('Test Student');
    studentId = res.body._id;
  });

  test('GET /api/v1/students - list students', async () => {
    const res = await request(app)
      .get('/api/v1/students')
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('data');
    expect(res.body).toHaveProperty('pagination');
  });

  test('PUT /api/v1/students/:id - update student', async () => {
    const res = await request(app)
      .put(`/api/v1/students/${studentId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Updated Student' });
    expect(res.statusCode).toBe(200);
    expect(res.body.name).toBe('Updated Student');
  });

  test('DELETE /api/v1/students/:id - delete student', async () => {
    const res = await request(app)
      .delete(`/api/v1/students/${studentId}`)
      .set('Authorization', `Bearer ${authToken}`);
    expect(res.statusCode).toBe(200);
  });
});

describe('Validation', () => {
  test('POST /api/v1/auth/register - missing fields', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ email: 'a@b.com' });
    expect(res.statusCode).toBe(400);
  });

  test('POST /api/v1/students - missing name', async () => {
    const res = await request(app)
      .post('/api/v1/students')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ phone: '1234567890' });
    expect(res.statusCode).toBe(400);
  });
});
