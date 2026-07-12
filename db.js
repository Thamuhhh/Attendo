const mongoose = require('mongoose');
const config = require('./config');
const logger = require('./utils/logger');

mongoose.connect(config.mongoUri).then(() => {
  logger.info('MongoDB connected');
}).catch(err => {
  logger.error('MongoDB connection error:', err.message);
  process.exit(1);
});

mongoose.connection.on('disconnected', () => {
  logger.warn('MongoDB disconnected');
});

mongoose.connection.on('error', (err) => {
  logger.error('MongoDB error', { error: err.message });
});

module.exports = mongoose;
