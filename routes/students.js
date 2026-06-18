const { Router } = require('express');
const studentController = require('../controllers/studentController');
const authMiddleware = require('../middleware/auth');

const router = Router();

router.get('/', authMiddleware, studentController.list);
router.post('/', authMiddleware, studentController.create);
router.put('/:id', authMiddleware, studentController.update);
router.delete('/:id', authMiddleware, studentController.remove);

module.exports = router;
