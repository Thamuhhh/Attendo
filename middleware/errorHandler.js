const logger = require('../utils/logger');

function notFound(req, res, _next) {
  res.status(404).json({ error: `Route ${req.method} ${req.originalUrl} not found` });
}

function errorHandler(err, req, res, _next) {
  logger.error('Unhandled error', {
    message: err.message,
    stack: err.stack,
    method: req.method,
    path: req.originalUrl,
  });

  if (err.name === 'CastError') {
    return res.status(400).json({ error: 'Invalid ID format' });
  }
  if (err.code === 11000) {
    return res.status(409).json({ error: 'Duplicate entry' });
  }
  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: err.message || 'Validation failed' });
  }

  const status = err.statusCode || err.status || 500;
  const message = process.env.NODE_ENV === 'production' ? 'Internal server error' : (err.message || 'Unknown error');
  res.status(status).json({ error: String(message) });
}

module.exports = { notFound, errorHandler };
