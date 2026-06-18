const { Router } = require('express');
const holidayController = require('../controllers/holidayController');
const authMiddleware = require('../middleware/auth');

const router = Router();

router.get('/', authMiddleware, holidayController.list);
router.post('/', authMiddleware, holidayController.create);
router.delete('/:date', authMiddleware, holidayController.remove);

module.exports = router;
