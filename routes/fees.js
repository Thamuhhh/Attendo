const { Router } = require('express');
const feeController = require('../controllers/feeController');
const authMiddleware = require('../middleware/auth');

const router = Router();

/**
 * @swagger
 * /api/v1/fees:
 *   get:
 *     summary: List fee records
 *     tags: [Fees]
 *     security:
 *       - bearerAuth: []
 *     parameters:
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
 *         description: Fee records
 */
router.get('/', authMiddleware, feeController.list);

/**
 * @swagger
 * /api/v1/fees:
 *   post:
 *     summary: Save fee records (bulk upsert)
 *     tags: [Fees]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               records:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       200:
 *         description: Updated fee records
 */
router.post('/', authMiddleware, feeController.save);

/**
 * @swagger
 * /api/v1/fees/summary:
 *   get:
 *     summary: Get fee summary for a year
 *     tags: [Fees]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: year
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Fee summary
 */
router.get('/summary', authMiddleware, feeController.summary);

module.exports = router;
