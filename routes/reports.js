const { Router } = require('express');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/auth');

const router = Router();

/**
 * @swagger
 * /api/v1/reports/monthly:
 *   get:
 *     summary: Get monthly attendance report
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
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
 *         description: Monthly report with percentages
 */
router.get('/monthly', authMiddleware, reportController.monthly);

module.exports = router;
