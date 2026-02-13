const express = require("express");
const { protect, authorize } = require("../middlewares/authMiddleware");

const {
    createGodown,
    getAllGodowns,
    getGodownById,
    updateGodown,
    deleteGodown
} = require("../controllers/godownControllers");

const router = express.Router();

router.post("/", protect, authorize('admin'), createGodown);
router.get("/", protect, authorize('admin'), getAllGodowns);
router.get("/:id", protect, authorize('admin'), getGodownById);
router.put("/:id", protect, authorize('admin'), updateGodown);
router.delete("/:id", protect, authorize('admin'), deleteGodown);

module.exports = router;