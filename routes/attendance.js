const { Router } = require('express');
const attendanceController = require('../controllers/attendanceController');
const authMiddleware = require('../middleware/auth');
const validate = require('../middleware/validate');
const { saveAttendanceSchema } = require('../middleware/schemas');

const router = Router();

/**
 * @swagger
 * /api/v1/attendance:
 *   get:
 *     summary: Get attendance by date or range
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: date
 *         schema:
 *           type: string
 *       - in: query
 *         name: studentId
 *         schema:
 *           type: string
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *       - in: query
 *         name: month
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Attendance records
 */
router.get('/', authMiddleware, attendanceController.getByDate);

/**
 * @swagger
 * /api/v1/attendance:
 *   post:
 *     summary: Save attendance records (bulk upsert)
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *               records:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     studentId:
 *                       type: string
 *                     status:
 *                       type: string
 *                       enum: [present, absent]
 *     responses:
 *       200:
 *         description: Updated attendance records
 */
router.post('/', authMiddleware, validate(saveAttendanceSchema), attendanceController.save);

/**
 * @swagger
 * /api/v1/attendance/today:
 *   get:
 *     summary: Get today's attendance overview
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Today's attendance data
 */
router.get('/today', authMiddleware, attendanceController.today);

/**
 * @swagger
 * /api/v1/attendance/history/{studentId}:
 *   get:
 *     summary: Get attendance history for a student
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: studentId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *       - in: query
 *         name: month
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Attendance history
 */
router.get('/history/:studentId', authMiddleware, attendanceController.history);

/**
 * @swagger
 * /api/v1/attendance/weekly:
 *   get:
 *     summary: Get weekly attendance summary
 *     tags: [Attendance]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: 7-day attendance summary
 */
router.get('/weekly', authMiddleware, attendanceController.weekly);

module.exports = router;
