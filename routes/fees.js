const { Router } = require('express');
const feeController = require('../controllers/feeController');
const authMiddleware = require('../middleware/auth');

const router = Router();

router.get('/', authMiddleware, feeController.list);
router.post('/', authMiddleware, feeController.save);
router.get('/summary', authMiddleware, feeController.summary);

module.exports = router;
