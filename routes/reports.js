const { Router } = require('express');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/auth');

const router = Router();

router.get('/monthly', authMiddleware, reportController.monthly);

module.exports = router;
