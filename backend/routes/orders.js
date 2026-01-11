const express = require("express");
const { protect, authorize } = require("../middlewares/authMiddleware");

const {createOrder, getMyOrders, getOrderById, userOrderStatus} = require("../controllers/orderControllers");

const router = express.Router();

router.post("/", protect, createOrder);

router.get("/myorders", getMyOrders);

router.get("/:id", getOrderById);

router.put("/:id/status",protect,authorize("admin", "pharmacy") , userOrderStatus);

module.exports = router;