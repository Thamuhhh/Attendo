const Joi = require('joi');

const registerSchema = Joi.object({
  name: Joi.string().trim().min(1).max(100).required(),
  email: Joi.string().trim().email().required(),
  phone: Joi.string().trim().allow('').max(20),
  password: Joi.string().min(6).max(100).required(),
});

const loginSchema = Joi.object({
  email: Joi.string().trim().email().required(),
  password: Joi.string().required(),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

const forgotPasswordSchema = Joi.object({
  email: Joi.string().trim().email().required(),
});

const resetPasswordSchema = Joi.object({
  token: Joi.string().required(),
  password: Joi.string().min(6).max(100).required(),
});

const createStudentSchema = Joi.object({
  name: Joi.string().trim().min(1).max(100).required(),
  phone: Joi.string().trim().allow('').max(20),
});

const updateStudentSchema = Joi.object({
  name: Joi.string().trim().min(1).max(100),
  phone: Joi.string().trim().allow('').max(20),
}).min(1);

const saveAttendanceSchema = Joi.object({
  date: Joi.string().isoDate(),
  records: Joi.array().items(Joi.object({
    studentId: Joi.string().required(),
    status: Joi.string().valid('present', 'absent').required(),
  })).min(1).required(),
});

const paginationSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  search: Joi.string().trim().allow('').max(100),
  sortBy: Joi.string().valid('name', 'createdAt', '-name', '-createdAt').default('name'),
});

module.exports = {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  createStudentSchema,
  updateStudentSchema,
  saveAttendanceSchema,
  paginationSchema,
};
