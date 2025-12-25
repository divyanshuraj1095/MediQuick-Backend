const express = require("express");

const {createOrder, getMyOrder, getOrderById, userOrderStatus} = require("../controllers/orderControllers");

const router = express.Router();

router.post("/", protect, createOrder);

router.get("/myorders", getMyOrder);

router.get("/:id", getOrderById);

router.put("/:id/status",protect,authorize("admin", "pharmacy") , userOrderStatus);

module.exports = router;