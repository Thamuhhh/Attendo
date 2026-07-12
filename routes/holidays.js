const { Router } = require('express');
const holidayController = require('../controllers/holidayController');
const authMiddleware = require('../middleware/auth');

const router = Router();

/**
 * @swagger
 * /api/v1/holidays:
 *   get:
 *     summary: List all holidays
 *     tags: [Holidays]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of holiday dates
 */
router.get('/', authMiddleware, holidayController.list);

/**
 * @swagger
 * /api/v1/holidays:
 *   post:
 *     summary: Add a holiday
 *     tags: [Holidays]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [date]
 *             properties:
 *               date:
 *                 type: string
 *               name:
 *                 type: string
 *     responses:
 *       200:
 *         description: Holiday added
 */
router.post('/', authMiddleware, holidayController.create);

/**
 * @swagger
 * /api/v1/holidays/{date}:
 *   delete:
 *     summary: Remove a holiday
 *     tags: [Holidays]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: date
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Holiday removed
 */
router.delete('/:date', authMiddleware, holidayController.remove);

module.exports = router;
