const express = require('express');
const { protect, authorize } = require('../middlewares/authMiddleware');
const { getAdminStats, getAllUsers, getGodowns, updateGodown, deleteGodown } = require('../controllers/adminController');

const router = express.Router();

router.get('/stats', protect, authorize('admin'), getAdminStats);
router.get('/users', protect, authorize('admin'), getAllUsers);
router.get('/godowns', protect, authorize('admin'), getGodowns);
router.put('/godowns/:id', protect, authorize('admin'), updateGodown);
router.delete('/godowns/:id', protect, authorize('admin'), deleteGodown);

module.exports = router;
