const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const config = require('./config');
const { notFound, errorHandler } = require('./middleware/errorHandler');
const logger = require('./utils/logger');

require('./db');

const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/students');
const attendanceRoutes = require('./routes/attendance');
const feeRoutes = require('./routes/fees');
const holidayRoutes = require('./routes/holidays');
const reportRoutes = require('./routes/reports');

const app = express();

app.use(helmet());
app.use(cors({ origin: config.cors.origin, credentials: true }));
app.use(express.json({ limit: '10mb' }));

if (config.env !== 'test') {
  app.use(morgan('combined', {
    stream: { write: (msg) => logger.info(msg.trim()) },
  }));
}

const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later' },
  skip: (req) => req.path === '/health' || req.path === '/app/version' || req.path === '/' || req.path === '/docs.json',
});
app.use('/api/', limiter);

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts, please try again later' },
});

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Attendo API',
      version: '2.0.0',
      description: 'Attendance Management System API',
    },
    servers: [
      { url: `http://localhost:${config.port}`, description: 'Development' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
    security: [{ bearerAuth: [] }],
  },
  apis: ['./routes/*.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customSiteTitle: 'Attendo API Docs',
}));
app.get('/api/docs.json', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

app.use('/api/v1/auth', (req, res, next) => {
  if (req.path === '/login' || req.path === '/register') return loginLimiter(req, res, next);
  next();
}, authRoutes);
app.use('/api/v1/students', studentRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/fees', feeRoutes);
app.use('/api/v1/holidays', holidayRoutes);
app.use('/api/v1/reports', reportRoutes);

app.use('/api/auth', (req, res, next) => {
  if (req.path === '/login' || req.path === '/register') return loginLimiter(req, res, next);
  next();
}, authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/fees', feeRoutes);
app.use('/api/holidays', holidayRoutes);
app.use('/api/report', reportRoutes);

app.get('/api', (req, res) => {
  res.json({ message: 'Attendo API is running', version: '2.0.0' });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    environment: config.env,
  });
});

app.get('/api/app/version', (req, res) => {
  res.json({
    version: '1.0.2',
    apkUrl: 'https://github.com/Thamuhhh/Attendo/releases/download/v1.0.2/app-release.apk',
    forceUpdate: false,
  });
});

app.use(notFound);
app.use(errorHandler);

module.exports = app;
