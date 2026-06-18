const { Router } = require('express');
const attendanceController = require('../controllers/attendanceController');
const authMiddleware = require('../middleware/auth');

const router = Router();

router.get('/', authMiddleware, attendanceController.getByDate);
router.post('/', authMiddleware, attendanceController.save);
router.get('/today', authMiddleware, attendanceController.today);
router.get('/history/:studentId', authMiddleware, attendanceController.history);
router.get('/weekly', authMiddleware, attendanceController.weekly);

module.exports = router;
