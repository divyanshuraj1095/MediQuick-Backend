const express = require("express");
const router = express.Router();
const { protect } = require("../middlewares/authMiddleware");
const {
    createSimpleOrder,
    getMySimpleOrders,
} = require("../controllers/simpleOrderController");

router.post("/", protect, createSimpleOrder);
router.get("/myorders", protect, getMySimpleOrders);

module.exports = router;
