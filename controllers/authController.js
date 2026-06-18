const crypto = require('crypto');
const bcrypt = require('bcrypt');
const Joi = require('joi');
const Institution = require('../models/Institution');

const SALT_ROUNDS = 10;

function generateToken() {
  return crypto.randomBytes(32).toString('hex');
}

function legacyHash(pw) {
  return crypto.createHash('sha256').update(pw).digest('hex');
}

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

exports.register = async (req, res) => {
  try {
    const { error, value } = registerSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { name, email, phone, password } = value;

    const existing = await Institution.findOne({ email: email.toLowerCase() });
    if (existing) return res.status(400).json({ error: 'Email already registered' });

    const hashed = await bcrypt.hash(password, SALT_ROUNDS);
    const token = generateToken();
    const inst = await new Institution({
      name, email: email.toLowerCase(), phone: phone || '', password: hashed, token,
    }).save();

    res.json({ token, institution: { id: inst._id, name: inst.name, email: inst.email } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) return res.status(400).json({ error: error.details[0].message });

    const { email, password } = value;
    const inst = await Institution.findOne({ email: email.toLowerCase() });
    if (!inst) return res.status(401).json({ error: 'Invalid email or password' });

    const match = await bcrypt.compare(password, inst.password);
    if (!match) {
      const legacyMatch = inst.password === legacyHash(password);
      if (!legacyMatch) return res.status(401).json({ error: 'Invalid email or password' });
      inst.password = await bcrypt.hash(password, SALT_ROUNDS);
      await inst.save();
    }

    res.json({ token: inst.token, institution: { id: inst._id, name: inst.name, email: inst.email } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.me = async (req, res) => {
  res.json({ institution: { id: req.institution._id, name: req.institution.name, email: req.institution.email } });
};
