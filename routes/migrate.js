const { Router } = require('express');
const migrateController = require('../controllers/migrateController');
const authMiddleware = require('../middleware/auth');

const router = Router();

router.post('/claim', authMiddleware, migrateController.claim);

module.exports = router;
