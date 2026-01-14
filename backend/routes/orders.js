const express = require("express");
const { protect, authorize } = require("../middlewares/authMiddleware");

const {createOrder, getMyOrders, getOrderById, userOrderStatus, cancelOrder} = require("../controllers/orderControllers");

const router = express.Router();

router.post("/", protect, createOrder);

router.get("/myorders", protect, getMyOrders);

router.get("/:id", getOrderById);

router.put("/:id/status",protect,authorize("admin", "pharmacy") , userOrderStatus);

router.put("/cancel/:id", protect, cancelOrder);

module.exports = router;