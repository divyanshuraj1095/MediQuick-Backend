const express = require("express");
const router = express.Router();

const { addToCart } = require("../controllers/cartControllers");

const {protect} = require("../middlewares/authMiddleware");
console.log("addToCart:", addToCart);
console.log("protect:", protect);


router.post("/add", protect, addToCart);

module.exports = router;
